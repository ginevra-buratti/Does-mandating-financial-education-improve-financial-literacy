program define pvreg, eclass
    syntax varlist(min=1) [if] [aweight], subject(string) pv(integer) [cluster(varname)]
	
	if `pv' < 2 {
		di as error "pvreg error: option pv() must be at least 2"
		error 498
	}
	
	ereturn clear
	
	cap matrix drop b V b_avg V_avg
	cap scalar drop N_1 r2_avg
	
    forvalues j = 1/`pv' {
        if "`cluster'" == "" {
			qui regress pv`j'`subject' `varlist' `if' [`weight' `exp']
		}
		else {
			qui regress pv`j'`subject' `varlist' `if' [`weight' `exp'], vce(cluster `cluster')
		}
		
        matrix b`j'   = e(b)
        matrix varw`j' = vecdiag(e(V))
        scalar r2_`j' = e(r2_a)
		scalar N_`j' = e(N)
    }
	
    local k = colsof(b1)
	scalar k_scalar = `k'
	
    mata {
		k = st_numscalar("k_scalar")
		b = J(1,k,0)
        varw = J(1,k,0)
		varb = J(1,k,0)
        r2adj = 0
		
		for (j=1; j<=`pv'; j++) {
            bj = st_matrix("b"+strofreal(j))
            varwj = st_matrix("varw"+strofreal(j))
            r2j = st_numscalar("r2_"+strofreal(j))
			
			b = b :+ bj
            varw = varw :+ varwj
            r2adj = r2adj + r2j
        }
		
		b = b :/ `pv'
		varw = varw :/ `pv'
		r2adj = r2adj / `pv'
		
		for (j=1; j<=`pv'; j++) {
            bj = st_matrix("b"+strofreal(j))

			diff = b :- bj
            varb = varb :+ (diff:^2)
        }
        varb = varb :/ (`pv'-1)
		
		rV = varw :+ (1+1/`pv') :* varb
		
		V = diag(rV)
		
		st_matrix("b", b)
		st_matrix("V", V)
		st_numscalar("r2adj", r2adj)
	}
	
	matname b `varlist' _cons, columns(.) explicit
	matname V `varlist' _cons, explicit
	
	ereturn post b V
	ereturn scalar r2_a = r2adj
	ereturn scalar N = N_1
	
	display "Number of obs. = " N_1
	display "Adj. R-squared = " r2adj
	ereturn display
	
	ereturn local cmd "pvreg"
end


//----------------------------------------------------------------------------//
// 00 - Main do file
// Author: A. Antonello, G. Buratti
// Date: 2026
// Description: This master do-file defines global paths and conditionally runs 
//				data preparation, descriptive statistics, and analyses.
//----------------------------------------------------------------------------//


clear all
set more off
set trace off


//----------------------------------------------------------------------------//


* Define root directory
global MAIN "Z:\Progetti di Ricerca\Valutazione_Trentino\replication_public" // <-- Update this path to match the location on your system

* Define paths
global DATA "${MAIN}/DATA"
global DO "${MAIN}/DO"
global TEMP "${MAIN}/TEMP"
global OUT "${MAIN}/OUT"
global TABFIG "${MAIN}/TABFIG"

* Change working directory
cd "${DO}"

* Choose do files to run: 1 to run, 0 to skip
global preparation 1
global descriptive 1
global analyses 1

* Start log
cap log close
log using "${OUT}/main_log.txt", text replace


//----------------------------------------------------------------------------//


* Run data preparation
if $preparation == 1 do "01_data_prep.do"

* Run descriptive statistics
if $descriptive == 1 do "02_descr_stats.do"

* Run analyses
if $analyses == 1 do "03_analyses.do"


//----------------------------------------------------------------------------//


cap log close


//----------------------------------------------------------------------------//

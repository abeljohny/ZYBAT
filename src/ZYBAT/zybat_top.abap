*&---------------------------------------------------------------------*
*&  Include           ZYBAT_TOP
*&---------------------------------------------------------------------*

************************************************************************
*                      SELECTION SCREEN                                *
************************************************************************
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE main.
PARAMETERS: pa_grpid LIKE apqi-groupid OBLIGATORY,
            pa_prg LIKE trdir-name OBLIGATORY.
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE trans.
PARAMETERS: rd_call TYPE c RADIOBUTTON GROUP rg1 DEFAULT 'X'.
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE mode.
PARAMETERS: rd_a TYPE c RADIOBUTTON GROUP rg2 MODIF ID m1,
            rd_n TYPE c RADIOBUTTON GROUP rg2 MODIF ID m1,
            rd_e TYPE c RADIOBUTTON GROUP rg2 MODIF ID m1.
SELECTION-SCREEN END OF BLOCK b3.
PARAMETERS: rd_batch TYPE c RADIOBUTTON GROUP rg1.
SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE table.
PARAMETERS pa_lines TYPE i.
SELECTION-SCREEN END OF BLOCK b4.
SELECTION-SCREEN END OF BLOCK b1.
*- PROGRAM VARIABLES --------------------------------------------------*
DATA: g_qid LIKE apqi-qid.
DATA: g_trans TYPE c LENGTH 1,
      g_mod TYPE c LENGTH 1.
DATA: active TYPE i,
      not_active TYPE i.
************************************************************************
*                            EVENTS                                    *
************************************************************************
INITIALIZATION.
  main = 'Parameters'(100).
  trans = 'Data Transfer Method'(101).
  mode = 'MODE'(102).
  table = 'Table Control Settings'(110).
  %_pa_grpid_%_app_%-text = 'Recording'(103).
  %_pa_prg_%_app_%-text = 'Program Name'(104).
  %_rd_call_%_app_%-text = 'CALL TRANSACTION USING'(105).
  %_rd_a_%_app_%-text = 'A (Display All)'(106).
  %_rd_e_%_app_%-text = 'E (Display Errors Only)'(107).
  %_rd_n_%_app_%-text = 'N (No Display)'(108).
  %_rd_batch_%_app_%-text = 'Batch Input'(109).
  %_pa_lines_%_app_%-text = 'Lines to Page Break'(111).

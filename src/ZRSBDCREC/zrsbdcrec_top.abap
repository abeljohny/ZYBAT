*&---------------------------------------------------------------------*
*&  Include           ZRSBDCREC_TOP
*&---------------------------------------------------------------------*

*- Macros -------------------------------------------------------------*
DEFINE append_clear_src.
  append source. clear source.
END-OF-DEFINITION.
*- Work Areas ---------------------------------------------------------*
DATA: dynprotab LIKE bdcdata OCCURS 0 WITH HEADER LINE.
DATA: BEGIN OF source OCCURS 100,
        line1(30),
        line2(42),
      END OF source.
DATA: BEGIN OF gwa_itab,
        name LIKE dd03l-fieldname,
        type TYPE field_type,
        kind(1) TYPE c,
      END OF gwa_itab.
DATA: text_tab   LIKE textpool OCCURS 0 WITH HEADER LINE,
      text_tab_2 LIKE textpool OCCURS 0 WITH HEADER LINE.
DATA: dynpro_fields LIKE bdcdf OCCURS 0 WITH HEADER LINE.
*- Internal tables ----------------------------------------------------*
DATA: git_itab LIKE STANDARD TABLE OF gwa_itab.
*- General vars -------------------------------------------------------*
DATA: tcode LIKE tstc-tcode.
DATA: dynpro_fields_index LIKE sy-tabix,
      tree_name(43).
DATA: idx TYPE i VALUE 14. " position of last declaration statement
DATA: tmp TYPE string.
*- Constants ----------------------------------------------------------*
CONSTANTS: c_flg1edt TYPE x VALUE '80'.
************************************************************************
*                      SELECTION SCREEN                                *
************************************************************************
PARAMETERS: qid      LIKE apqd-qid,
            report   LIKE trdir-name,
            trans    TYPE char1 NO-DISPLAY,
            mod      TYPE char1 NO-DISPLAY,
            pa_lines TYPE i,
            testdata NO-DISPLAY,
            dsn(132) NO-DISPLAY,
            file     NO-DISPLAY.

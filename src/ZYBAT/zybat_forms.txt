*&---------------------------------------------------------------------*
*&  Include           ZYBAT_FORMS
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  init
*&---------------------------------------------------------------------*
FORM init.
  IF rd_call = 'X'.
    g_trans = 'C'.
    CASE rd_call.
      WHEN rd_a.
        g_mod = 'A'.
      WHEN rd_n.
        g_mod = 'N'.
      WHEN rd_e.
        g_mod = 'E'.
    ENDCASE.
  ELSE.
    g_trans = 'B'.
  ENDIF.
ENDFORM.                    "init
*&---------------------------------------------------------------------*
*&      Form  select_data
*&---------------------------------------------------------------------*
FORM select_data.
  SELECT SINGLE qid FROM apqi
  INTO g_qid
  WHERE groupid = pa_grpid.
ENDFORM.                    "select_data
*&---------------------------------------------------------------------*
*&      Form  program_create
*&---------------------------------------------------------------------*
*       creation & composition of program and source code
*----------------------------------------------------------------------*
*      -->P_PROGNAME text
*----------------------------------------------------------------------*
FORM program_create USING p_progname TYPE trdir-name.
  TABLES trdir.
  DATA: l_progname LIKE trdir-name..
  DATA: l_answer.
  DATA: l_subrc LIKE sy-subrc.
  DATA: l_leave_to_editor.

  l_progname = p_progname.
  CALL FUNCTION 'RS_PROGRAM_CHECK_NAME'
    EXPORTING
      progname = l_progname
    EXCEPTIONS
      OTHERS   = 04.
  IF sy-subrc >< 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
* program should not exist
  SELECT SINGLE * FROM trdir WHERE name = l_progname.
  IF sy-subrc = 0.
    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
      EXPORTING
        defaultoption = 'N'
        textline1     = 'Program Already Exists'(040)
        textline2     = 'Delete,& Create new one?'(041)
        titel         = 'Create New Program'(042)
        start_column  = 25
        start_row     = 6
      IMPORTING
        answer        = l_answer.
    IF l_answer = 'J'.
      PERFORM delete_program USING l_progname CHANGING l_subrc.
      IF l_subrc = 0.
        MESSAGE ID 'MS' TYPE 'I' NUMBER 611 WITH l_progname.
      ELSE.
        EXIT.
      ENDIF.
    ELSE.
      EXIT.
    ENDIF.
  ENDIF.
* create program attributes
  CLEAR trdir.
  trdir-name = l_progname.
  trdir-subc = '1'.
  CALL FUNCTION 'RS_EDTR_ATTR_ADD'
    EXPORTING
      program_name          = l_progname
      called_by_shdb        = 'X'
      with_trdir_entry      = 'X'
    IMPORTING
      leave_to_editor       = l_leave_to_editor
    CHANGING
      program_trdir         = trdir
    EXCEPTIONS
      program_name_missing  = 1
      program_exists        = 2
      wrong_parameter_value = 3
      OTHERS                = 4.
  IF sy-subrc >< 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
* attributes saved?
  SELECT SINGLE * FROM trdir WHERE name = trdir-name.
  CHECK sy-subrc = 0.
* create program
  SUBMIT zrsbdcrec AND RETURN
         WITH qid      = g_qid
         WITH report   = pa_prg
         WITH trans    = g_trans
         WITH mod      = g_mod
         WITH pa_lines    = pa_lines
         WITH testdata = ' '
         WITH dsn      = ' '
         WITH file     = ' '.
  SET PARAMETER ID 'RID' FIELD trdir-name.
* editor if chosen within attributes
  IF l_leave_to_editor = 'X'.
    CALL FUNCTION 'EDITOR_PROGRAM'
      EXPORTING
        program   = trdir-name
        trdir_inf = trdir.
  ENDIF.
ENDFORM.                    "program_create
*&---------------------------------------------------------------------*
*&      Form  DELETE_PROGRAM
*&---------------------------------------------------------------------*
*      -->P_L_PROGNAME  text
*      <--P_L_SUBRC  text
*----------------------------------------------------------------------*
FORM delete_program USING    p_progname
                    CHANGING p_subrc.
  DATA:  l_devclass LIKE tadir-devclass.

  CALL FUNCTION 'RS_PROGRAM_GET_DEVCLASS'
       EXPORTING
           progname = p_progname
       IMPORTING
           devclass = l_devclass
       EXCEPTIONS
           OTHERS.
  CALL FUNCTION 'RS_DELETE_PROGRAM'
    EXPORTING
      program            = p_progname
      suppress_popup     = ' '
      tadir_devclass     = l_devclass
    EXCEPTIONS
      enqueue_lock       = 1
      object_not_found   = 2
      permission_failure = 3
      reject_deletion    = 5     "abbr. in popup
      OTHERS             = 4.
  p_subrc = sy-subrc.
  IF sy-msgno = '055'. p_subrc = 1. ENDIF.  "progr. gesperrt
  IF p_subrc < 5.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " DELETE_PROGRAM

*&---------------------------------------------------------------------*
*&  Include           ZRSBDCREC_FORMS
*&---------------------------------------------------------------------*

**** source_line_for_field_content ************************************
FORM source_line_for_field_content USING p_fval.
  DATA: l_fval LIKE dynprotab-fval.
  l_fval = p_fval.
  IF l_fval+39 = space.
    CONCATENATE ''''
                l_fval
                '''.'
                INTO source-line2.
    append_clear_src.
  ELSE.                "field content longer than 38
    CONCATENATE ''''
                l_fval(38)
                ''''
                INTO source-line2.
    append_clear_src.
    source-line1+28 = '&'.
    DO 4 TIMES.
      SHIFT l_fval BY 38 PLACES.
      IF l_fval+39 = space.
        CONCATENATE ''''
                    l_fval
                    '''.'
                    INTO source-line2.
        append_clear_src.
        EXIT.
      ELSE.                "field content longer than n x 38
        CONCATENATE ''''
                    l_fval(38)
                    ''''
                    INTO source-line2.
        APPEND source. CLEAR source-line2.
      ENDIF.
    ENDDO.
  ENDIF.
ENDFORM.               "SOURCE_LINE_FOR_FIELD_CONTENT
**** source_line_for_var_field ****************************************
FORM source_line_for_var_field.
  IF dynprotab-fnam = 'BDC_OKCODE' OR
     dynprotab-fnam = 'BDC_CURSOR' OR
     dynprotab-fnam = 'BDC_SUBSCR'.
    PERFORM source_line_for_field_content USING dynprotab-fval.
  ELSE.
    ADD 1 TO dynpro_fields_index.
    READ TABLE dynpro_fields INDEX dynpro_fields_index.
    IF sy-subrc <> 0.
      MESSAGE a614 WITH dynprotab-fnam.
    ENDIF.
    CONCATENATE 'record-'
                dynpro_fields-recfield
                '.'
                INTO source-line2.
    append_clear_src.
  ENDIF.
ENDFORM.               "SOURCE_LINE_FOR_VAR_FIELD
**** fill_dynpro_fields ***********************************************
FORM fill_dynpro_fields.

  CALL FUNCTION 'BDC_DYNPROTAB_GET_FIELDS'
    TABLES
      dynprotab    = dynprotab
      dynprofields = dynpro_fields.

ENDFORM.                    "FILL_DYNPRO_FIELDS

**** source_lines_for_record ******************************************
FORM source_lines_for_record.
  DATA: l_dfies     LIKE dfies,
        l_tabname   LIKE dcobjdef-name,
        l_fieldname LIKE dfies-lfieldname,
        l_dummy     LIKE dfies-lfieldname.

* create comment lines for record
  source = '***    DO NOT CHANGE - the generated data section - '
           &'DO NOT CHANGE    ***'.
  append_clear_src.
  source = '*'.
  append_clear_src.
  source = '*   If it is nessesary to change the data section'
           &' use the rules:'.
  append_clear_src.
  source = '*   1.) Each definition of a field exists of two lines'.
  append_clear_src.
  source = '*   2.) The first line shows exactly the comment'.
  append_clear_src.
  source = '*       ''* data element: '' '
           &'followed with the data element'.
  append_clear_src.
  source = '*       which describes the field.'.
  append_clear_src.
  source = '*       If you don''t have a data element use the'.
  append_clear_src.
  source = '*       comment without a data element name'.
  append_clear_src.
  source = '*   3.) The second line shows the fieldname of the'.
  append_clear_src.
  source = '*       structure, the fieldname must consist of'.
  append_clear_src.
  source = '*       a fieldname and optional the character ''_'' and'.
  append_clear_src.
  source = '*       three numbers and the field length in brackets'.
  append_clear_src.
  source = '*   4.) Each field must be type C.'.
  append_clear_src.
  source = '*'.
  append_clear_src.
  source = '*** Generated data section with specific formatting - '
           &'DO NOT CHANGE  ***'.
  append_clear_src.
* *** data: begin of record,
  source = 'data: begin of record,'.
  append_clear_src.
  LOOP AT dynpro_fields.
*   *** <field_n>(<length>)
    CLEAR l_dfies.
    IF dynpro_fields-fieldname CA '-'.
*     create dataelement comment line
      SPLIT dynpro_fields-fieldname AT '-'
            INTO l_tabname
                 l_fieldname.
      SPLIT l_fieldname AT '('
            INTO l_fieldname
                 l_dummy.
      CALL FUNCTION 'DDIF_FIELDINFO_GET'
        EXPORTING
          tabname        = l_tabname
          lfieldname     = l_fieldname
        IMPORTING
          dfies_wa       = l_dfies
        EXCEPTIONS
          not_found      = 1
          internal_error = 2
          OTHERS         = 3.
      IF sy-subrc <> 0.
        CLEAR l_dfies.
      ENDIF.
    ENDIF.
    source    = '* data element: '.
    source+16 = l_dfies-rollname.
    append_clear_src..
    CONCATENATE dynpro_fields-recfield
                '(' dynpro_fields-length ')' ','
                INTO source+8.
    append_clear_src.
  ENDLOOP.
* *** end   of record.
  source = '      end of record.'.
  append_clear_src.. append_clear_src..
  source = '*** End generated data section ***'.
  append_clear_src.. append_clear_src..
ENDFORM.                    "SOURCE_LINES_FOR_RECORD
**** create_testfile **************************************************
FORM create_testfile.
  DATA: l_buffer(65535),
        l_off LIKE sy-tabix,
        l_len LIKE sy-tabix,
        l_sum LIKE sy-tabix.
  FIELD-SYMBOLS: <l_sym>.

  OPEN DATASET dsn
               FOR APPENDING IN TEXT MODE
               ENCODING DEFAULT.
  IF sy-subrc <> 0.
    MESSAGE s619 WITH dsn.
    EXIT.
  ENDIF.
  CLEAR: l_buffer, l_off.
  LOOP AT dynpro_fields.
    l_len = dynpro_fields-length.
    l_sum = l_len + l_off.
    IF l_sum > 65535 OR l_len = 0.
      MESSAGE a604 WITH 'CREATE_TESTFILE' l_sum.
    ENDIF.
    ASSIGN l_buffer+l_off(l_len) TO <l_sym>.
    <l_sym> = dynpro_fields-fieldvalue.
    ADD dynpro_fields-length TO l_off.
  ENDLOOP.
  TRANSFER l_buffer TO dsn LENGTH l_off.
  CLOSE DATASET dsn.
ENDFORM.                    "CREATE_TESTFILE
*&---------------------------------------------------------------------*
*&      Form  DELETE_LINE
*&---------------------------------------------------------------------*
*      -->P_3      text
*----------------------------------------------------------------------*
FORM delete_source_line  USING    value(p_line).
  READ TABLE source INDEX p_line INTO source.
  DELETE source INDEX p_line.
ENDFORM.                    " DELETE_LINE
*&---------------------------------------------------------------------*
*&      Form  scan_src
*&---------------------------------------------------------------------*
*      <--P_SOURCE  text
*----------------------------------------------------------------------*
FORM scan_src  CHANGING p_src TYPE STANDARD TABLE.
  DATA: wa_src LIKE source.
  DATA: regex_nrm TYPE string VALUE '([''])([[:alnum:]]+)-([[:alnum:]]+)\1[^.]',
        regex_tab TYPE string VALUE '([''])([[:alnum:]]+)-([[:alnum:]]+)\(\d+\)\1[^.]'.
  DATA: lit_results TYPE match_result_tab.
  DATA: l_off TYPE i, l_len TYPE i.
  DATA: tmp TYPE string.
  DATA: l_found_nrm TYPE c LENGTH 1,
        l_found_tab TYPE c LENGTH 1.
  DATA: strlen TYPE i,
        l_tabix LIKE sy-tabix,
        l_cnt_int TYPE i VALUE 1,
        l_cnt_str TYPE string VALUE 1.
  LOOP AT p_src INTO wa_src.
    l_tabix = sy-tabix.
    CONDENSE wa_src-line2 NO-GAPS.
    FIND ALL OCCURRENCES OF REGEX regex_nrm IN wa_src-line2 RESULTS lit_results IGNORING CASE.
    IF sy-subrc = 0.
      l_found_nrm = 'X'.
      gwa_itab-kind = 'N'.
      REPLACE ALL OCCURRENCES OF '''' IN wa_src-line2 WITH ''.
      gwa_itab-type = wa_src-line2.
      SPLIT wa_src-line2 AT '-' INTO tmp gwa_itab-name.
      READ TABLE git_itab WITH KEY name = gwa_itab-name TRANSPORTING NO FIELDS.
      IF sy-subrc >< 0.
        APPEND gwa_itab TO git_itab.
      ENDIF.
    ELSEIF l_found_nrm = 'X'.
      CLEAR source.
      l_found_nrm = space.
      CONCATENATE 'gwa_itab-' gwa_itab-name '.' INTO source-line2.
      MODIFY source INDEX l_tabix.
    ELSE.
      FIND ALL OCCURRENCES OF REGEX regex_tab IN wa_src-line2 RESULTS lit_results IGNORING CASE.
      IF sy-subrc = 0.
        l_found_tab = 'X'.
        gwa_itab-kind = 'T'.
        REPLACE ALL OCCURRENCES OF '''' IN wa_src-line2 WITH ''.
        strlen = strlen( wa_src-line2 ).
        strlen = strlen - 4 .
        gwa_itab-type = wa_src-line2(strlen).
        SPLIT gwa_itab-type AT '-' INTO tmp gwa_itab-name.
        READ TABLE git_itab WITH KEY name = gwa_itab-name TRANSPORTING NO FIELDS.
        IF sy-subrc >< 0.
          APPEND gwa_itab TO git_itab.
        ENDIF.
        CLEAR source-line2.
        CONCATENATE 'CONCATENATE' '''' INTO tmp SEPARATED BY space.
        CONCATENATE tmp gwa_itab-type '(' '''' INTO tmp.
        CONCATENATE tmp 'gc_count' '''' INTO tmp SEPARATED BY space.
        CONCATENATE tmp ')' '''' INTO tmp.
        CONCATENATE tmp 'INTO g_string.' INTO tmp SEPARATED BY space.
        PERFORM insert_src USING l_tabix:  tmp.
        source-line2 = 'g_string'.
        source-line1 = wa_src-line1.
        MODIFY source INDEX l_tabix.
      ELSEIF l_found_tab = 'X'.
        CLEAR source.
        l_found_tab = space.
        CONCATENATE 'gwa_itab-' gwa_itab-name '.'
                                                  INTO source-line2.
        MODIFY source INDEX l_tabix.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " scan_src
*&---------------------------------------------------------------------*
*&      Form  insert_scan_source
*&---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM insert_scan_source .
  CLEAR: source.
  source = 'DATA: BEGIN OF gwa_itab,'.
  INSERT source INDEX idx.
  CLEAR source.
  LOOP AT git_itab INTO gwa_itab.
    idx = idx + 1.
    CONCATENATE gwa_itab-name 'TYPE' gwa_itab-type INTO source SEPARATED BY space.
    CONCATENATE source ',' INTO source.
    INSERT source INDEX idx.
    CLEAR source.
  ENDLOOP.
  idx = idx + 1.
  source = 'END OF gwa_itab,'.
  INSERT source INDEX idx.
  idx = idx + 1.
  source = 'git_itab LIKE STANDARD TABLE OF gwa_itab.'.
  INSERT source INDEX idx.
ENDFORM.                    " insert_scan_source
*&---------------------------------------------------------------------*
*&      Form  insert_pgm_src
*&---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM insert_pgm_src .
  DATA: str_tmp TYPE string,
        str_tmp2 LIKE str_tmp.
  idx = idx + 1.
  PERFORM insert_src USING idx:   'DATA: str_fname TYPE string.',
                                  'PARAMETERS: filename LIKE ibipparms-path.',
                                  '',
                                  'AT SELECTION-SCREEN ON VALUE-REQUEST FOR filename.',
                                  'CALL FUNCTION ''F4_FILENAME''',
                                  'EXPORTING',
                                  'program_name  = syst-cprog',
                                  'dynpro_number = syst-dynnr',
                                  'IMPORTING',
                                  'file_name     = filename.',
                                  '',
                                  'START-OF-SELECTION.',
                                  'str_fname = filename.',
                                  'CALL METHOD cl_gui_frontend_services=>gui_upload',
                                  'EXPORTING',
                                  'filename                = str_fname',
                                  'filetype                = ''ASC''',
                                  'has_field_separator     = ''x''',
                                  'CHANGING',
                                  'data_tab                = git_itab',
                                  'EXCEPTIONS',
                                  'file_open_error         = 1',
                                  'file_read_error         = 2',
                                  'no_batch                = 3',
                                  'gui_refuse_filetransfer = 4',
                                  'invalid_type            = 5',
                                  'no_authority            = 6',
                                  'unknown_error           = 7',
                                  'bad_data_format         = 8',
                                  'header_not_allowed      = 9',
                                  'separator_not_allowed   = 10',
                                  'header_too_long         = 11',
                                  'unknown_dp_error        = 12',
                                  'access_denied           = 13',
                                  'dp_out_of_memory        = 14',
                                  'disk_full               = 15',
                                  'dp_timeout              = 16',
                                  'not_supported_by_gui    = 17',
                                  'error_no_gui            = 18',
                                  'OTHERS                  = 19.',
                                  'IF sy-subrc <> 0.',
                                  'MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno',
                                  'WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.',
                                  'ENDIF.'.
  IF trans = 'B'.
    PERFORM insert_src USING idx: 'CALL FUNCTION ''BDC_OPEN_GROUP''',
                                  'EXPORTING',
                                  'client              = sy-mandt',
                                  'group               = ''ZYBAT''',
                                  'keep                = ''X''',
                                  'user                = sy-uname',
                                  'prog                = sy-cprog',
                                  'EXCEPTIONS',
                                  'client_invalid      = 1',
                                  'destination_invalid = 2',
                                  'group_invalid       = 3',
                                  'group_is_locked     = 4',
                                  'holddate_invalid    = 5',
                                  'internal_error      = 6',
                                  'queue_error         = 7',
                                  'running             = 8',
                                  'system_lock_error   = 9',
                                  'user_invalid        = 10',
                                  'OTHERS              = 11.',
                                  'IF sy-subrc <> 0.',
                                    'MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno',
                                            'WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.',
                                  'ENDIF.'.
  ENDIF.
  PERFORM insert_src USING idx:   'LOOP AT git_itab INTO gwa_itab.',
                                  'REFRESH bdcdata.',
                                  'PERFORM recording.'.
  IF trans = 'C'.
    CLEAR: str_tmp, str_tmp2.
    CONCATENATE '' tcode '' INTO str_tmp SEPARATED BY ''''.
    CONCATENATE '''' mod '''.' INTO str_tmp2.
    CONCATENATE 'CALL TRANSACTION' str_tmp 'USING BDCDATA MODE' str_tmp2 INTO source SEPARATED BY space.
    INSERT source INDEX idx.
  ELSE.
    PERFORM insert_src USING idx:   'CALL FUNCTION ''BDC_INSERT''',
                                    'EXPORTING'.
    CONCATENATE '' tcode '' INTO str_tmp SEPARATED BY ''''.
    CONCATENATE 'tcode            =' str_tmp INTO str_tmp SEPARATED BY space.
    PERFORM insert_src USING idx:   str_tmp,
                                    'TABLES',
                                    'dynprotab        = bdcdata',
                                    'EXCEPTIONS',
                                    'internal_error   = 1',
                                    'not_open         = 2',
                                    'queue_error      = 3',
                                    'tcode_invalid    = 4',
                                    'printing_invalid = 5',
                                    'posting_invalid  = 6',
                                    'OTHERS           = 7.',
                                    'IF sy-subrc <> 0.',
                                    'MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno',
                                    'WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.',
                                    'ENDIF.'.
  ENDIF.
  PERFORM insert_src USING idx:   'ENDLOOP.'.
  IF trans = 'B'.
    PERFORM insert_src USING idx:   'CALL FUNCTION ''BDC_CLOSE_GROUP''',
                                    'EXCEPTIONS',
                                    'not_open    = 1',
                                    'queue_error = 2',
                                    'OTHERS      = 3.',
                                    'IF sy-subrc <> 0.',
                                    'MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno',
                                    'WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.',
                                    'ENDIF.'.
  ENDIF.
ENDFORM.                    " insert_pgm_src
*&---------------------------------------------------------------------*
*&      Form  INSERT_SRC
*&---------------------------------------------------------------------*
*      -->IDX        text
*----------------------------------------------------------------------*
FORM insert_src USING idx TYPE i
                value(str) TYPE string.
  source = str.
  INSERT source INDEX idx.
  CLEAR: source. idx = idx + 1.
ENDFORM.                    "INSERT_SRC

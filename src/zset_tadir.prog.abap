************************************************************************
*
*  Beschreibung  : Setzt in ABAP-Objekten das Originalsystem
*
************************************************************************
*  ABAP Name     : zset_tadir
*  Author        : Max Mustermann
************************************************************************
REPORT zset_tadir MESSAGE-ID 38.

TABLES tadir.

CLASS lcl_appl DEFINITION DEFERRED.

TYPE-POOLS:
  abap,
  slis,
  icon,
  sdydo.

* ALV-Daten
TYPES: BEGIN OF gty_alv.
        INCLUDE STRUCTURE tadir.
TYPES:
         icon(4),
         style   TYPE lvc_t_styl,
         color   TYPE slis_t_specialcol_alv,
         mark,
       END OF gty_alv,
  gty_t_alv TYPE STANDARD TABLE OF gty_alv.


DATA:
   go_appl TYPE REF TO lcl_appl.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
SELECT-OPTIONS s_pgmid  FOR tadir-pgmid NO INTERVALS DEFAULT 'R3TR'.
SELECT-OPTIONS s_object FOR tadir-object.
SELECT-OPTIONS s_obname FOR tadir-obj_name.
SELECT-OPTIONS s_orgsys FOR tadir-srcsystem NO INTERVALS.
SELECT-OPTIONS s_devcla FOR tadir-devclass.
SELECT-OPTIONS s_malang FOR tadir-masterlang.
SELECTION-SCREEN END   OF BLOCK b1.

CLASS lcl_appl DEFINITION.
  PUBLIC SECTION.
    DATA:
          mt_data              TYPE STANDARD TABLE OF gty_alv,
          mt_data_old          TYPE STANDARD TABLE OF gty_alv,
          mt_list_top_of_page  TYPE slis_t_listheader,
          mt_fieldcat          TYPE lvc_t_fcat,
          mv_anzahl            TYPE i,
          mv_callback_programm TYPE sy-repid,
          mv_repid             TYPE syrepid,
          mv_variant_save      TYPE c,
          ms_vbak              TYPE vbak,
          ms_data              TYPE gty_alv,
          ms_variant           TYPE disvariant,
          ms_grid_scroll       TYPE lvc_s_scrl.

    METHODS:
      init,
      f4_variant
        CHANGING
          cs_variant TYPE disvariant,
      get_data,
      set_status
        CHANGING
          ct_excl TYPE slis_t_extab,
      handle_fcode
        CHANGING
          cs_selfield TYPE slis_selfield
          cv_okcode   TYPE syucomm,
      display.

  PRIVATE SECTION.
    METHODS:
      save,
      set_top_of_page,
      set_editable_fields,
      refresh
        CHANGING
          cs_selfield TYPE slis_selfield,
      set_target_system
        CHANGING
          cs_selfield TYPE slis_selfield.

ENDCLASS.

CLASS lcl_appl IMPLEMENTATION.

  METHOD init.
    DATA ls_variant TYPE disvariant.

    mv_repid             = sy-repid.
    mv_callback_programm = sy-repid.

    ms_variant-report     = mv_repid.

    ls_variant = ms_variant.

    CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
      CHANGING
        cs_variant    = ls_variant
      EXCEPTIONS
        wrong_input   = 1
        not_found     = 2
        program_error = 3
        OTHERS        = 4.

    IF sy-subrc <> 0.
    ELSE.
      ms_variant = ls_variant.
    ENDIF.

    mv_variant_save = 'A'.

  ENDMETHOD.

  METHOD set_status.
* Ausschlus von Standardfunktionen
    DATA ls_exclude TYPE ui_func.

    ls_exclude = cl_gui_alv_grid=>mc_fc_detail.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_check.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_cut.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_copy.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_paste.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_paste_new_row.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_copy_row.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_mb_filter.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_filter.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_sum.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_average.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_minimum.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_maximum.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_mb_subtot.
    APPEND ls_exclude TO ct_excl.
*
    ls_exclude = cl_gui_alv_grid=>mc_fc_subtot.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_print_back.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_view_crystal.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_view_excel.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_view_grid.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_view_lotus.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_to_office.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_call_abc.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_call_xint.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_url_copy_to_clipboard.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_expcrdesig.
    APPEND ls_exclude TO ct_excl.
*
    ls_exclude = cl_gui_alv_grid=>mc_fc_expcrtempl.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_mb_variant.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_load_variant.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_current_variant.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_save_variant.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_maintain_variant.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_call_more.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_reprep.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_call_master_data.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_graph.
    APPEND ls_exclude TO ct_excl.

    ls_exclude = cl_gui_alv_grid=>mc_fc_info.
    APPEND ls_exclude TO ct_excl.

    SET PF-STATUS 'STATUS_ALV' EXCLUDING ct_excl.

  ENDMETHOD.

  METHOD f4_variant.
    CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
      EXPORTING
        is_variant    = cs_variant
      IMPORTING
        es_variant    = cs_variant
      EXCEPTIONS
        not_found     = 0
        program_error = 0
        OTHERS        = 0.
  ENDMETHOD.

  METHOD get_data.
    DATA:
          lt_data TYPE STANDARD TABLE OF tadir,
          ls_data TYPE tadir.

    CLEAR mt_data.

*   Daten besorgen
    SELECT * INTO TABLE lt_data
             FROM tadir
             WHERE pgmid      IN s_pgmid
               AND object     IN s_object
               AND obj_name   IN s_obname
               AND srcsystem  IN s_orgsys
               AND devclass   IN s_devcla
               AND masterlang IN s_malang.

    SORT lt_data.
    LOOP AT lt_data INTO ls_data.

      CLEAR ms_data.
      MOVE-CORRESPONDING ls_data TO ms_data.
      ms_data-icon = icon_change.

      APPEND ms_data TO mt_data.

    ENDLOOP.

    SORT mt_data.

    DESCRIBE TABLE mt_data LINES mv_anzahl.
    EXPORT mv_anzahl FROM mv_anzahl TO MEMORY ID sy-repid.

    mt_data_old[] = mt_data[].
  ENDMETHOD.

  METHOD display.
    CONSTANTS:
               lc_pf_status         TYPE slis_formname VALUE 'ALV_STATUS',
               lc_user_command      TYPE slis_formname VALUE 'ALV_COMMAND',
               lc_internal_tab_name TYPE slis_tabname  VALUE 'MT_DATA',
               lc_structure_name    TYPE dd02l-tabname VALUE 'TADIR',
               lc_data_changed      TYPE slis_formname VALUE 'ALV_DATA_CHANGED',
               lc_top_of_page       TYPE slis_formname VALUE 'ALV_TOP_OF_PAGE',
               lc_field_mark        TYPE slis_layout_alv-box_fieldname VALUE 'MARK',
               lc_field_style       TYPE slis_layout_alv-box_fieldname VALUE 'STYLE',
               lc_field_color       TYPE slis_layout_alv-box_fieldname VALUE 'COLOR'.

    DATA:
          lt_excluding     TYPE slis_t_extab,
          lt_events        TYPE slis_t_event,
          lt_list_sort     TYPE lvc_t_sort,
          ls_sort          TYPE lvc_s_sort,
          ls_layout        TYPE lvc_s_layo,
          ls_fieldcat      TYPE lvc_s_fcat,
          ls_grid_settings TYPE lvc_s_glay,
          ls_event         TYPE slis_alv_event.

    FIELD-SYMBOLS:
                   <lf_fcat> TYPE lvc_s_fcat.

    set_top_of_page( ).

*   Layout einstellen
    ls_layout-edit       = abap_true.
    ls_layout-zebra      = abap_true.
    ls_layout-numc_total = abap_true.
    ls_layout-box_fname  = lc_field_mark.
    ls_layout-stylefname = lc_field_style.
    ls_layout-ctab_fname = lc_field_color.

    ls_grid_settings-edt_cll_cb   = abap_true.

*   Events anmelden
    CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
      EXPORTING
        i_list_type = 0
      IMPORTING
        et_events   = lt_events.

*   Top of Page
    READ TABLE lt_events INTO ls_event
         WITH KEY name = slis_ev_top_of_page
                             .
    IF sy-subrc = 0.
      MOVE lc_top_of_page TO ls_event-form.
      MODIFY lt_events FROM ls_event INDEX sy-tabix.
    ELSE.
      MOVE lc_top_of_page TO ls_event-form.
      APPEND ls_event TO lt_events.
    ENDIF.
    ls_event-name = 'DATA_CHANGED'.
    ls_event-form = lc_data_changed.
    APPEND ls_event TO mt_list_top_of_page.

*   Feldkatalog lesen
    CLEAR mt_fieldcat.

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_internal_tabname     = lc_internal_tab_name
        i_structure_name       = lc_structure_name
        i_client_never_display = abap_true
      CHANGING
        ct_fieldcat            = mt_fieldcat.

*   Feldkatalog anpassen
    LOOP AT mt_fieldcat ASSIGNING <lf_fcat>.

      CASE <lf_fcat>-fieldname.
        WHEN 'EDTFLAG'    OR
             'CPROJECT'   OR
             'PAKNOCHECK' OR
             'OBJSTABLTY' OR
             'COMPONENT'  OR
             'CRELEASE'   OR
             'VERSID'     OR
             'GENFLAG'    OR
             'TRANSLTTXT'.
          <lf_fcat>-no_out      = abap_true.

      ENDCASE.

    ENDLOOP.

*   Default-Sortierung
    ls_sort-spos      = '01'.
    ls_sort-fieldname = 'PGMID'.
    ls_sort-up        = abap_true.
    APPEND ls_sort TO lt_list_sort.

    ls_sort-spos      = '02'.
    ls_sort-fieldname = 'OBJECT'.
    ls_sort-up        = abap_true.
    APPEND ls_sort TO lt_list_sort.

    ls_sort-spos      = '03'.
    ls_sort-fieldname = 'OBJ_NAME'.
    ls_sort-up        = abap_true.
    APPEND ls_sort TO lt_list_sort.

*   EDIT-Felder einstellen
    set_editable_fields( ).

*   ALV-Liste ausgeben
    mt_data_old[] = mt_data[].

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
      EXPORTING
        i_bypassing_buffer       = abap_true
        i_callback_program       = mv_callback_programm
        i_callback_pf_status_set = lc_pf_status
        i_callback_user_command  = lc_user_command
        i_grid_settings          = ls_grid_settings
        is_layout_lvc            = ls_layout
        it_fieldcat_lvc          = mt_fieldcat
        it_excluding             = lt_excluding
        it_sort_lvc              = lt_list_sort
        i_default                = abap_true
        i_save                   = mv_variant_save
        is_variant               = ms_variant
        it_events                = lt_events
      TABLES
        t_outtab                 = mt_data
      EXCEPTIONS
        OTHERS                   = 0.

  ENDMETHOD.

  METHOD set_top_of_page.
    DATA:
          ls_style     TYPE lvc_s_styl,
          ls_line      TYPE slis_listheader,
          lv_text(50),
          lv_line(100).

    IMPORT mv_anzahl TO mv_anzahl FROM MEMORY ID sy-repid.
    WRITE mv_anzahl TO lv_text.

*   Listenüberschrift: Typ H
    CLEAR ls_line.
    ls_line-typ   = 'H'.
    APPEND ls_line TO mt_list_top_of_page.

    CLEAR ls_line.
    ls_line-typ   = 'H'.
    CONCATENATE text-s01 lv_text INTO lv_line SEPARATED BY space.
    CONDENSE lv_line.
    ls_line-info = lv_line.
    APPEND ls_line TO mt_list_top_of_page.

  ENDMETHOD.

  METHOD set_editable_fields.
    DATA:
          ls_style     TYPE lvc_s_styl.

    FIELD-SYMBOLS:
                   <lf_fcat> TYPE lvc_s_fcat,
                   <lf_data> TYPE gty_alv.

*   EDIT-Felder einstellen
    SORT mt_fieldcat BY fieldname.

    LOOP AT mt_data ASSIGNING <lf_data>.

      LOOP AT mt_fieldcat ASSIGNING <lf_fcat>.

        CLEAR ls_style.
        ls_style-fieldname = <lf_fcat>-fieldname.

        CASE <lf_fcat>-fieldname.
          WHEN 'SRCSYSTEM'.
            ls_style-style  = cl_gui_alv_grid=>mc_style_enabled.
            APPEND ls_style TO <lf_data>-style.

          WHEN OTHERS.
            ls_style-style  = cl_gui_alv_grid=>mc_style_disabled.
            APPEND ls_style TO <lf_data>-style.
        ENDCASE.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

  METHOD handle_fcode.
    DATA ls_data TYPE gty_alv.                                                 "#EC NEEDED

    IF cs_selfield-tabindex > 0.
      READ TABLE mt_data INTO ls_data INDEX cs_selfield-tabindex.
    ENDIF.

    CASE cv_okcode.
*     Auffrischen
      WHEN 'REFR'.
        refresh( CHANGING cs_selfield = cs_selfield ).

      WHEN 'TASYS'.
        set_target_system( CHANGING cs_selfield = cs_selfield ).

      WHEN 'SAVE'.
        IF mt_data_old[] NE mt_data[].
          save( ).
          refresh( CHANGING cs_selfield = cs_selfield ).
        ENDIF.

    ENDCASE.
  ENDMETHOD.

  METHOD save.
    DATA:
          lv_anz       TYPE i,
          lv_anz_c     TYPE char10,
          ls_tadir_new TYPE tadir.

    LOOP AT mt_data INTO ms_data.

      CALL FUNCTION 'TRINT_TADIR_UPDATE'
        EXPORTING
          pgmid                = ms_data-pgmid
          object               = ms_data-object
          obj_name             = ms_data-obj_name
          srcsystem            = ms_data-srcsystem
        EXCEPTIONS
          object_has_no_tadir  = 1
          object_exists_global = 2
          OTHERS               = 3.

      IF sy-subrc = 0.
        ADD 1 TO lv_anz.
        COMMIT WORK.
      ELSE.
        ROLLBACK WORK.
      ENDIF.
    ENDLOOP.

    WRITE lv_anz TO lv_anz_c.

    SHIFT lv_anz_c LEFT DELETING LEADING '0'.
    CONDENSE lv_anz_c NO-GAPS.

    MESSAGE s000(38) WITH 'Es wurden' lv_anz_c 'Sätze geändert'.

  ENDMETHOD.

  METHOD set_target_system.
    DATA:
          lv_srcsystem  TYPE tadir-srcsystem,
          lv_retcodepop TYPE char1,
          ls_field      TYPE sval,
          lt_fields     TYPE STANDARD TABLE OF sval.

    FIELD-SYMBOLS
     <lf_data> LIKE LINE OF mt_data.

    CLEAR lt_fields.
    ls_field-tabname   = 'TADIR'.
    ls_field-fieldname = 'SRCSYSTEM'.
    ls_field-fieldtext = 'Neues Originalsystem'(002).
    APPEND ls_field TO lt_fields.

    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING
        popup_title     = 'Reservierung'(001)
        start_column    = '17'
        start_row       = '5'
      IMPORTING
        returncode      = lv_retcodepop
      TABLES
        fields          = lt_fields
      EXCEPTIONS
        error_in_fields = 1
        OTHERS          = 2.

    IF lv_retcodepop NE 'A'.
      READ TABLE lt_fields INTO ls_field INDEX 1.
      lv_srcsystem = ls_field-value.

      LOOP AT mt_data ASSIGNING <lf_data>.
        <lf_data>-srcsystem = lv_srcsystem.
      ENDLOOP.
    ENDIF.

    cs_selfield-refresh    = abap_true.
    cs_selfield-row_stable = abap_true.

  ENDMETHOD.

  METHOD refresh.

    get_data( ).

    set_top_of_page( ).
    set_editable_fields( ).

    cs_selfield-refresh    = abap_true.
    cs_selfield-row_stable = abap_true.

    mt_data_old = mt_data.

  ENDMETHOD.

ENDCLASS.

LOAD-OF-PROGRAM.
  CREATE OBJECT go_appl.

INITIALIZATION.
  go_appl->init( ).

START-OF-SELECTION.
  go_appl->get_data( ).
  go_appl->display( ).


*&---------------------------------------------------------------------*
*&      Form  alv40_status
*&---------------------------------------------------------------------*
FORM alv_status USING rt_extab TYPE slis_t_extab.                              "#EC CALLED
  go_appl->set_status( CHANGING ct_excl = rt_extab ).
ENDFORM.                                                                       "alv_status

*&---------------------------------------------------------------------*
*&      Form  alv50_command
*&---------------------------------------------------------------------*
FORM alv_command USING rv_ucomm    TYPE sy-ucomm
                       rs_selfield TYPE slis_selfield.                         "#EC CALLED
  go_appl->handle_fcode( CHANGING cs_selfield = rs_selfield
                                  cv_okcode   = rv_ucomm ).
ENDFORM.                                                                       "alv_command

*&---------------------------------------------------------------------*
*&      Form  alv90_top_of_page
*&---------------------------------------------------------------------*
FORM alv_top_of_page.                                                          "#EC CALLED
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      i_logo             = 'Z_LOGO_SMURFIT_KAPPA'
      it_list_commentary = go_appl->mt_list_top_of_page.
ENDFORM.                                                                       "TOP_OF_PAGE

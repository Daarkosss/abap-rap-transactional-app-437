CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ZZvalidateClass FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~ZZvalidateClass.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD ZZvalidateClass.
    CONSTANTS c_area TYPE string VALUE `CLASS`.

    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY item
      FIELDS ( agencyid travelid ZZClassZ74 )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      INSERT VALUE #(
        %tky = <item>-%tky
        %state_area = c_area
      ) INTO TABLE reported-item.

      IF <item>-ZZClassZ74 IS INITIAL.
        INSERT VALUE #( %tky = <item>-%tky ) INTO TABLE failed-item.
        INSERT VALUE #(
          %tky = <item>-%tky
          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
          %element-ZZClassZ74 = if_abap_behv=>mk-on
          %state_area = c_area
          %path-travel = CORRESPONDING #( <item> )
        ) INTO TABLE reported-item.
      ELSE.
        SELECT SINGLE
          FROM /lrn/437_i_classstdvh
          FIELDS classid
          WHERE classid = @<item>-ZZClassZ74
          INTO @DATA(dummy).

        IF sy-subrc <> 0.
          INSERT VALUE #( %tky = <item>-%tky ) INTO TABLE failed-item.

          INSERT VALUE #(
            %tky = <item>-%tky
            %msg = NEW /lrn/cm_s4d437(
              textid = /lrn/cm_s4d437=>class_not_exist
              classid = <item>-ZZClassZ74
            )
            %element-ZZClassZ74 = if_abap_behv=>mk-on
            %state_area = c_area
            %path-travel = CORRESPONDING #( <item> )
          ) INTO TABLE reported-item.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z7409_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z7409_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.
    DATA(items) = update-item.
    INSERT LINES OF create-item INTO TABLE items.

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>) WHERE %control-ZZClassZ74 = if_abap_behv=>mk-on.
      UPDATE z7409_tritem
        SET zzclassz74 = @<item>-ZZClassZ74
        WHERE item_uuid = @<item>-ItemUuid.
    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.

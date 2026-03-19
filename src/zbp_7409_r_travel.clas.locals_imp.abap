CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateFlightDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateFlightDate.
    METHODS determineTravelDates FOR DETERMINE ON SAVE
      IMPORTING keys FOR Item~determineTravelDates.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD validateFlightDate.
    CONSTANTS c_area TYPE string VALUE `FLIGHTDATE`.

    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Item
      FIELDS ( AgencyId TravelId FlightDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      INSERT VALUE #(
        %tky = <item>-%tky
        %state_area = c_area
      ) INTO TABLE reported-item.

      IF <item>-FlightDate IS INITIAL.
        INSERT VALUE #( %tky = <item>-%tky ) INTO TABLE failed-item.
        INSERT VALUE #(
          %tky = <item>-%tky
          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
          %element-FlightDate = if_abap_behv=>mk-on
          %state_area = c_area
          %path-travel = CORRESPONDING #( <item> )
        ) INTO TABLE reported-item.
      ELSEIF <item>-FlightDate < cl_abap_context_info=>get_system_date( ).
        INSERT VALUE #( %tky = <item>-%tky ) INTO TABLE failed-item.
        INSERT VALUE #(
          %tky = <item>-%tky
          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>flight_date_past )
          %element-FlightDate = if_abap_behv=>mk-on
          %state_area = c_area
          %path-travel = CORRESPONDING #( <item> )
        ) INTO TABLE reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determineTravelDates.
    READ ENTITIES OF Z7409_R_Travel IN LOCAL MODE
      ENTITY Item
      FIELDS ( FlightDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items)
      BY \_Travel
      FIELDS ( BeginDate EndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels)
      LINK DATA(link).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      ASSIGN travels[ KEY id
        %tky = link[ KEY id source-%tky = <item>-%tky ]-target-%tky
      ] TO FIELD-SYMBOL(<travel>).

      IF <travel>-EndDate < <item>-FlightDate.
        <travel>-EndDate = <item>-FlightDate.
      ENDIF.

      IF <item>-FlightDate > cl_abap_context_info=>get_system_date( )
      AND <item>-FlightDate < <travel>-BeginDate.
        <travel>-BeginDate = <item>-FlightDate.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF Z7409_R_Travel  IN LOCAL MODE
      ENTITY Travel
      UPDATE
      FIELDS ( BeginDate EndDate )
      WITH CORRESPONDING #( travels ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS cancel_travel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~cancel_travel.
    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDescription.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.
    METHODS validateBeginDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateBeginDate.

    METHODS validateDateSequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateDateSequence.

    METHODS validateEndDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateEndDate.
    METHODS determineStatus FOR DETERMINE ON SAVE
      IMPORTING keys FOR Travel~determineStatus.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.
    METHODS determineduration FOR DETERMINE ON SAVE
      IMPORTING keys FOR travel~determineduration.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
    result = CORRESPONDING #( keys ).
    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).
      DATA(rc) = /lrn/cl_s4d437_model=>authority_check(
        i_agencyid  = <result>-agencyid
        i_actvt = '02'
      ).

      IF rc <> 0.
*        <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
*        <result>-%update = if_abap_behv=>auth-unauthorized.
      ELSE.
        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
        <result>-%update = if_abap_behv=>auth-allowed.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.
    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    MODIFY ENTITIES OF Z7409_R_TRAVEL IN LOCAL MODE
      ENTITY travel
      UPDATE FIELDS ( status )
      WITH VALUE #(
        FOR travel IN travels
        WHERE ( status <> 'C' )
        (
          %tky = travel-%tky
          status = 'C'
        )
      ).

    reported-travel = VALUE #(
      FOR trav IN travels
      WHERE ( status = 'C' )
      (
        %tky = trav-%tky
        %msg = NEW zcm_7409_travel(
          textid = zcm_7409_travel=>already_canceled
        )
      )
    ).
  ENDMETHOD.

  METHOD validateDescription.
    CONSTANTS c_area TYPE string VALUE `DESC`.

    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      INSERT VALUE #(
        %tky = <travel>-%tky
        %state_area = c_area
      ) INTO TABLE reported-travel.

      IF <travel>-Description IS INITIAL.
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
          %element-Description = if_abap_behv=>mk-on
          %state_area = c_area
        ) INTO TABLE reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateCustomer.
    CONSTANTS c_area TYPE string VALUE 'CUST'.

    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    SELECT FROM /dmo/i_customer
      FIELDS CustomerID
      FOR ALL ENTRIES IN @travels
      WHERE CustomerID = @travels-CustomerId
      INTO TABLE @DATA(customers).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      INSERT VALUE #(
        %tky = <travel>-%tky
        %state_area = c_area
      ) INTO TABLE reported-travel.

      IF <travel>-CustomerID IS INITIAL.
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
          %element-CustomerID = if_abap_behv=>mk-on
          %state_area = c_area
        ) INTO TABLE reported-travel.
      ELSEIF NOT line_exists( customers[ customerid = <travel>-CustomerId ] ).
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437(
            textid = /lrn/cm_s4d437=>customer_not_exist
            customerid = <travel>-CustomerId
          )
          %element-CustomerId = if_abap_behv=>mk-on
          %state_area = c_area
        ) INTO TABLE reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateBeginDate.
    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-BeginDate IS INITIAL.
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
          %element-BeginDate = if_abap_behv=>mk-on
        ) INTO TABLE reported-travel.
      ELSEIF <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>begin_date_past )
          %element-BeginDate = if_abap_behv=>mk-on
        ) INTO TABLE reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateEndDate.
    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-EndDate IS INITIAL.
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
          %element-EndDate = if_abap_behv=>mk-on
        ) INTO TABLE reported-travel.
      ELSEIF <travel>-EndDate < cl_abap_context_info=>get_system_date( ).
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>end_date_past )
          %element-EndDate = if_abap_behv=>mk-on
        ) INTO TABLE reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDateSequence.
    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      IF <travel>-EndDate < <travel>-BeginDate.
        INSERT VALUE #( %tky = <travel>-%tky ) INTO TABLE failed-travel.
        INSERT VALUE #(
          %tky = <travel>-%tky
          %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>dates_wrong_sequence )
          %element = VALUE #(
            BeginDate = if_abap_behv=>mk-on
            EndDate = if_abap_behv=>mk-on
          )
        ) INTO TABLE reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user(  ).
    mapped-travel = CORRESPONDING #( entities ).

      LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapped>).
        <mapped>-AgencyId = agencyid.
        <mapped>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid( ).
      ENDLOOP.
  ENDMETHOD.

  METHOD determineStatus.
    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    DELETE travels WHERE Status IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    MODIFY ENTITIES OF Z7409_R_Travel IN LOCAL MODE
      ENTITY Travel
      UPDATE FIELDS ( Status )
      WITH VALUE #(
        FOR key IN travels (
          %tky = key-%tky
          Status = 'N'
        )
      )
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      FIELDS ( Status BeginDate EndDate )
      WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      INSERT CORRESPONDING #( <travel> ) INTO TABLE result ASSIGNING FIELD-SYMBOL(<result>).

      IF <travel>-%is_draft = if_abap_behv=>mk-on.
        READ ENTITIES OF z7409_r_travel IN LOCAL MODE
          ENTITY Travel
          FIELDS ( BeginDate EndDate )
          WITH VALUE #( ( %key = <travel>-%key ) )
          RESULT DATA(travels_active).

        IF travels_active IS NOT INITIAL.
          <travel>-BeginDate = travels_active[ 1 ]-BeginDate.
          <travel>-EndDate   = travels_active[ 1 ]-EndDate.
        ELSE.
          CLEAR <travel>-BeginDate.
          CLEAR <travel>-EndDate.
        ENDIF.
      ENDIF.

      IF <travel>-Status = 'C' OR (
        <travel>-EndDate IS NOT INITIAL
        AND <travel>-EndDate < cl_abap_context_info=>get_system_date( )
      ).
        <result>-%update = if_abap_behv=>fc-o-disabled.
        <result>-%features-%update = if_abap_behv=>fc-o-disabled.
        <result>-%action-Edit = if_abap_behv=>fc-o-disabled.
      ELSE.
        <result>-%update = if_abap_behv=>fc-o-enabled.
        <result>-%action-cancel_travel = if_abap_behv=>fc-o-enabled.
      ENDIF.

      IF <travel>-BeginDate IS NOT INITIAL
      AND <travel>-BeginDate < cl_abap_context_info=>get_system_date( ).
        <result>-%field-CustomerId = if_abap_behv=>fc-f-read_only.
        <result>-%field-BeginDate = if_abap_behv=>fc-f-read_only.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD determineDuration.
    READ ENTITIES OF z7409_r_travel IN LOCAL MODE
      ENTITY Travel
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    MODIFY ENTITIES OF Z7409_R_Travel IN LOCAL MODE
      ENTITY Travel
      UPDATE FIELDS ( Duration )
      WITH VALUE #(
        FOR travel IN travels (
          %tky = travel-%tky
          Duration = travel-EndDate - travel-BeginDate
        )
      ).
  ENDMETHOD.

ENDCLASS.

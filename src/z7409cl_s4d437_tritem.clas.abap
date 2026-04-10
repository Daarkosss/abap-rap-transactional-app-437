CLASS z7409cl_s4d437_tritem DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        i_table_name TYPE tabname   "Name of the DB Table for travel items
      RAISING
        cx_sy_dynamic_osql_error.

    METHODS delete_item "Delete an existing travel item in the DB table
      IMPORTING
        i_uuid           TYPE /lrn/437_s_tritem-item_uuid
      RETURNING
        VALUE(r_message) TYPE symsg.

    METHODS create_item "create a new travel item in the DB table
      IMPORTING
        i_item           TYPE /lrn/437_s_tritem  "data set to be added to the DB table
      RETURNING
        VALUE(r_message) TYPE symsg.

    METHODS update_item "Update an existing travel item in the DB table
      IMPORTING
        i_item           TYPE /lrn/437_s_tritem   "new data for the existing dataset
        i_itemx          TYPE /lrn/437_s_tritemx  "fields that are to be updated
      RETURNING
        VALUE(r_message) TYPE symsg.


  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA table_name TYPE tabname.

    DATA item TYPE REF TO data.

    DATA max_booking_id TYPE /dmo/booking_id.

    CONSTANTS offset_booking_id TYPE /dmo/booking_id VALUE '1000'.

    METHODS get_next_booking_id
      RETURNING
        VALUE(r_result) TYPE /dmo/booking_id.

ENDCLASS.



CLASS Z7409CL_S4D437_TRITEM IMPLEMENTATION.


  METHOD constructor.

    me->table_name = i_table_name.

* Dynamically create work area for database table
    CREATE DATA item TYPE z7409_tritem.

* Init counter for booking ID (simulation for number range)
* In case of error -> propagate exception to caller
    SELECT FROM (table_name)
         FIELDS MAX( booking_id )
           INTO @max_booking_id.

    IF sy-subrc <> 0.
      max_booking_id = offset_booking_id.
    ENDIF.


  ENDMETHOD.


  METHOD create_item.

    ASSIGN item->* TO FIELD-SYMBOL(<item>).
    CLEAR <item>.
    <item> = CORRESPONDING #( i_item ).
*   Add Booking ID
    ASSIGN COMPONENT 'BOOKING_ID' OF STRUCTURE <item> TO FIELD-SYMBOL(<booking_id>).
    IF sy-subrc = 0.
      <booking_id> = get_next_booking_id( ).
    ENDIF.
    INSERT (table_name) FROM @<item>.

    IF sy-subrc <> 0.

      r_message = VALUE #( msgid = '/LRN/S4D437'
                           msgno =  '710'
                           msgty = 'E'
                           msgv1 = i_item-item_uuid
                         ).
    ELSE.
      r_message = VALUE #( msgid = '/LRN/S4D437'
                           msgno =  '711'
                           msgty = 'S'
                           msgv1 = i_item-item_uuid
                          ).
    ENDIF.

  ENDMETHOD.


  METHOD delete_item.

* Check existence

    DELETE FROM (table_name) WHERE item_uuid = @i_uuid.

    IF sy-subrc <> 0.

      r_message = VALUE #( msgid = '/LRN/S4D437'
                           msgno = '700'
                           msgty = 'E'
                           msgv1 = i_uuid
                          ).
    ELSE.
      r_message = VALUE #( msgid = '/LRN/S4D437'
                           msgno = '701'
                           msgty = 'S'
                           msgv1 = i_uuid
                         ).
    ENDIF.

  ENDMETHOD.


  METHOD get_next_booking_id.

    max_booking_id += 1.
    r_result = max_booking_id.

  ENDMETHOD.


  METHOD update_item.

*    DATA ls_item TYPE /lrn/437f_tritem.
    ASSIGN item->* TO FIELD-SYMBOL(<item>).
    CLEAR <item>.

* Read existing data set from DB
    SELECT SINGLE *
             FROM (table_name)
            WHERE item_uuid = @i_item-item_uuid
             INTO @<item>.

    IF sy-subrc <> 0.

    ENDIF.

* Merge importing parameter and existing data set
    LOOP AT CAST cl_abap_structdescr(
                             cl_abap_typedescr=>describe_by_name( table_name )
                           )->components
            INTO DATA(component).

      ASSIGN COMPONENT component-name OF STRUCTURE <item>  TO FIELD-SYMBOL(<field>).
      ASSIGN COMPONENT component-name OF STRUCTURE i_item  TO FIELD-SYMBOL(<comp>).
      ASSIGN COMPONENT component-name OF STRUCTURE i_itemx TO FIELD-SYMBOL(<compx>).

      IF sy-subrc = 0.
        IF <compx> = abap_true.
          <field> = <comp>.
        ENDIF.
      ENDIF.

    ENDLOOP.

* Update DB
    UPDATE (table_name) FROM @<item>.

    IF sy-subrc <> 0.

      r_message = VALUE #( msgid = '/LRN/S4D437'
                           msgno =  '720'
                           msgty = 'E'
                           msgv1 = i_item-item_uuid
                         ).
    ELSE.
      r_message = VALUE #( msgid = '/LRN/S4D437'
                           msgno =  '721'
                           msgty = 'S'
                           msgv1 = i_item-item_uuid
                          ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.

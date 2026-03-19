CLASS zcl_7409_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070000'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00008595'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_7409_EML IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
*    READ ENTITIES OF z7409_r_travel
*      ENTITY Travel
*      ALL FIELDS WITH VALUE #( (
*        AgencyId = c_agency_id
*        TravelId = c_travel_id
*      ) )
*      RESULT DATA(travels)
*      FAILED DATA(failed).
*
*    IF failed IS NOT INITIAL.
*      out->write( |Error while retrieving the travel. Error: { failed-Travel[ 1 ]-%fail-cause }| ).
*      RETURN.
*    ENDIF.
*
*    MODIFY ENTITIES OF z7409_r_travel IN LOCAL MODE
*      ENTITY Travel
*      UPDATE FIELDS ( Status )
*      WITH VALUE #( FOR travel IN travels (
*        AgencyId = travel-agency_id
*        TravelId = travel-travel_id
*        Status = 'N'
*      ) )
*      FAILED DATA(failed).
*
*    IF failed IS NOT INITIAL.
*      ROLLBACK ENTITIES.
*      out->write( `Error while updating the description` ).
*      RETURN.
*    ENDIF.
*
*    COMMIT ENTITIES.
*    out->write( `Description successfully updated` ).

    UPDATE z7409_travel
      SET status = 'N'
      WHERE status = 'C'.
  ENDMETHOD.
ENDCLASS.

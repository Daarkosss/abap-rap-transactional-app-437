@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel Item'
@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AbapCatalog.extensibility: {
  extensible: true,
  allowNewDatasources: false,
  dataSources: ['_Extension'],
  elementSuffix: 'Z74'
}
define view entity Z7409_R_TRAVELITEM
  as select from z7409_tritem
  association to parent Z7409_R_TRAVEL as _Travel    on  $projection.TravelId = _Travel.TravelId
                                                     and $projection.AgencyId = _Travel.AgencyId
  association to Z7409_E_TravelItem      as _Extension on  $projection.ItemUuid = _Extension.ItemUuid
{
  key item_uuid            as ItemUuid,
      agency_id            as AgencyId,
      travel_id            as TravelId,
      carrier_id           as CarrierId,
      connection_id        as ConnectionId,
      flight_date          as FlightDate,
      booking_id           as BookingId,
      passenger_first_name as PassengerFirstName,
      passenger_last_name  as PassengerLastName,
      @Semantics.systemDateTime.lastChangedAt: true
      changed_at           as ChangedAt,
      @Semantics.user.lastChangedBy: true
      changed_by           as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      loc_changed_at       as LocChangedAt,

      _Travel,
      _Extension
}

@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel (Projection)'
@ObjectModel.modelingPattern: #ANALYTICAL_QUERY
@ObjectModel.supportedCapabilities: [#ANALYTICAL_QUERY]
@Search.searchable: true
@Metadata.allowExtensions: true
define root view entity Z7409_C_Travel
provider contract transactional_query
as projection on Z7409_R_TRAVEL
{
  key AgencyId,
  @Search.defaultSearchElement: true
  key TravelId,
  @Search.defaultSearchElement: true
  Description,
  @Consumption.valueHelpDefinition: [{ entity: { name: '/DMO/I_Customer_StdVH' , element: 'CustomerID' } }]
  CustomerId,
  BeginDate,
  EndDate,
  @EndUserText.label: 'Duration (days)'
  Duration,
  Status,
  ChangedAt,
  ChangedBy,
  LocChangedAt,
  _TravelItem : redirected to composition child Z7409_C_TravelItem
}

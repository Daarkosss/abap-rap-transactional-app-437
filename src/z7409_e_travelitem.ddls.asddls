@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension Include for Travel Items'
@Metadata.ignorePropagatedAnnotations: true
@AbapCatalog.extensibility: {
  extensible: true,
  allowNewDatasources: false,
  dataSources: ['Item'],
  elementSuffix: 'Z74'
}
define view entity Z7409_E_TravelItem
  as select from z7409_tritem as Item
{
  key item_uuid as ItemUuid
}

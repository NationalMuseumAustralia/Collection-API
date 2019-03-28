<c:result xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:cx="http://xmlcalabash.com/ns/extensions" content-type="text/plain" cx:decode="true">
| Path | Field | Label | Datatype | Description | Examples | Linked Art |
| ---- | ----- | ----- | -------- | ----------- | -------- | ---------- |
| `` | `id` | Object record number | integer | Unique catalogue internal record number for the object | `12345` | `identified_by`&lt;br /&gt;(`classified_as aat:300404621`)|
| `` | `type` | Type | string | Over-arching object type, currently all records have the value of object | `object` | ``|
| `` | `additionalType` | Object type | string | Type of object with the primary object type listed first, with a secondary object type listed on occasions. | `Rugs` &lt;br /&gt;`Mineral specimens` &lt;br /&gt;`Sculptures` &lt;br /&gt;`Spearthrowers` | `classified_as`|
| `` | `title` | Title | string | Title given to the object | `Bark canoe` | `label`|
| `collection` | `id` | Collection record number | string | Catalogue internal record number for the collection | `4567` | `part_of`|
| `collection` | `type` | Collection type | string | API entity type for the collection | `Collection` | ``|
| `collection` | `title` | Collection title | string | The name of the collection | | ``|
| `` | `identifier` | Accession number | string | Accession number assigned to the object | `1984.0010.0721` | `identified_by`&lt;br /&gt;(`classified_as aat:300312355`)|
| `` | `medium` | Materials | string | Physical material types in the object | `Feather` &lt;br /&gt;`Wax - non specific` | `made_of`|
| `extent` | `length` | Length | float | Length of the object | `123` &lt;br /&gt;`45.6` | `dimension`&lt;br /&gt;(`classified_as aat:300055645`)|
| `extent` | `height` | Height | float | Height of the object | `123` &lt;br /&gt;`45.6` | `dimension`&lt;br /&gt;(`classified_as aat:300055644`)|
| `extent` | `width` | Width | float | Width of the object | `123` &lt;br /&gt;`45.6` | `dimension`&lt;br /&gt;(`classified_as aat:300055647`)|
| `extent` | `depth` | Depth | float | Depth of the object (dimension) | `123` &lt;br /&gt;`45.6` | `dimension`&lt;br /&gt;(`classified_as aat:300072633`)|
| `extent` | `diameter` | Diameter | float | Diameter of the object | `123` &lt;br /&gt;`45.6` | `dimension`&lt;br /&gt;(`classified_as aat:300055624`)|
| `extent` | `weight` | Weight | float | Weight of the object | `123` &lt;br /&gt;`45.6` | `dimension`&lt;br /&gt;(`classified_as aat:300056240`)|
| `extent` | `unitText` | Length unit | string | Unit type for the object's size measurements | `mm` &lt;br /&gt;`cm` &lt;br /&gt;`m` | `dimension/unit`|
| `extent` | `unitTextWeight` | Weight unit | string | Unit type for the object's weight | `g` &lt;br /&gt;`kg` &lt;br /&gt;`oz` &lt;br /&gt;`lb` &lt;br /&gt;`tonne` | `dimension/unit`|
| `` | `description` | Description | string | Description of the object and its signficance. | `This hat was worn by Muriel McPhee. McPhee's family believe that around 1916 McPhee became engaged, although they don't know to whom. They believe he was killed on the Western Front. Following the loss of her fiancÃ© during the First World War, McPhee wore black clothing and accessories as a reminder of her loss and grief. They are signifiers of her unstated yet lifelong mourning.` | `subject_of`&lt;br /&gt;(`classified_as nma:contentDescription`)&lt;br /&gt;(`classified_as aat:300411780`)|
| `` | `physicalDescription` | Physical description | string | Physical description of the object | `Glass plate negative` | `subject_of`&lt;br /&gt;(`classified_as nma:physicalDescription`)&lt;br /&gt;(`classified_as aat:300411780`)|
| `` | `significanceStatement` | Statement of significance | string | Describes the collection in which the objects belongs and its significance. | `This collection consists of a number of objects relating to the life of Muriel McPhee (1899 -1986). These include shoes, a hat and hatbox, gold bracelet and ring, mourning brooch, WWI era cards and photographs, lamp, women's clothing and undergarments, stockings, gloves, handmade post-partum abdominal binder and breast-feeding camisole, grocers invoices and hand-embroidered doily.` | `subject_of`&lt;br /&gt;(`classified_as nma:significanceStatement`)&lt;br /&gt;(`classified_as aat:300379612`)|
| `` | `educationalSignificance` | Educational significance | string | Information about the object of educational value | `This is a plaster death mask of the head of bushranger Ned Kelly, including the neck and partial right shoulder. Ned Kelly was hanged at Melbourne Gaol on the morning of 11 November 1880. Immediately after his body was taken down from the gallows, his hair and beard were shaved off and a mould taken of his head by Maximilien Kreitmayer. The mask is a unique three-dimensional representation of one of Australia's better-known historical figures, created shortly after his death...` | `subject_of`&lt;br /&gt;(`classified_as nma:educationalSignificance`)&lt;br /&gt;(`classified_as aat:300379612`)|
| `creator` | `id` | Creator record number | integer | Catalogue internal record number for the creator | `8230` | `produced_by/consists_of/carried_out_by/identified_by`&lt;br /&gt;(`classified_as aat:300404621`)|
| `creator` | `type` | Creator type | string | The type of creator. This will either be a person or an organisation. | `Person` &lt;br /&gt;`Organisation` | ``|
| `creator` | `title` | Creator name | string | The name of the creator | `Angkaliya Brumby` | ``|
| `creator` | `roleName` | Creator role | string | The role this creator played in creating the object | `maker` &lt;br /&gt;`photographer` &lt;br /&gt;`builder` | `produced_by/consists_of/label`|
| `creator` | `description` | Creator notes | string | Notes about this part of creating the object | `There are other branches noted: London, Melbourne and Brisbane.` | `produced_by/consists_of/subject_of`&lt;br /&gt;(`classified_as aat:300411780`)|
| `creator` | `interactionType` | Creator action type | string | The type of action taken by the creator | `Production` | `-`|
| `contributor` | `id` | Associated party record number | integer | NMA EMu Catalogue record number for the associated party | | `present_at/involved/identified_by`|
| `contributor` | `type` | Associated party type | string | API entity type for the associated party | `Person` &lt;br /&gt;`Organisation` | ``|
| `contributor` | `title` | Associated party name | string | The name of the associated party | | ``|
| `contributor` | `roleName` | Associated party role | string | How this party is associated with the object | | `present_at/label`|
| `contributor` | `description` | Associated party notes | string | Notes about this party's association with the object | | `present_at/subject_of`&lt;br /&gt;(`classified_as aat:300411780`)|
| `spatial` | `interactionType` | Place action type | string | The type of action that the place was involved in | `Production` | `-`|
| `spatial` | `id` | Associated place record number | integer |  | | `present_at/involved/identified_by`|
| `spatial` | `type` | Associated place type | string | API entity type for the place | `Place` | ``|
| `spatial` | `title` | Associated place name | string | The name of the place | `Auckland` | ``|
| `spatial` | `roleName` | Associated place role | string | How this location is associated with the object | `Place collected` | `present_at/label`|
| `spatial` | `description` | Associated place notes | string | Notes about this location's association with the object | | `present_at/subject_of`&lt;br /&gt;(`classified_as aat:300411780`)|
| `spatial` | `geo` | Associated place geo coordinates | string | The GPS lat/long co-ordinates for the place | `-35.3,149.13` | `produced_by/consists_of/took_place_at/place_is_defined_by/value`&lt;br /&gt;(`classified_as aat:300380194`)|
| `temporal` | `interactionType` | Production date action type | string | The type of action that the date was involved in | `Production` | `-`|
| `temporal` | `type` | Associated date type | string | API entity type for the date | `Event` | ``|
| `temporal` | `title` | Associated date | date | Associated date | | `present_at/timespan/label`|
| `temporal` | `roleName` | Role | string | How this date is associated with the object | `Date photographed` | `present_at/label`|
| `temporal` | `startDate` | Associated date earliest | date | Earliest associated date | | `present_at/timespan/begin_of_the_begin`|
| `temporal` | `endDate` | Associated date latest | date | Latest associated date | | `present_at/timespan/end_of_the_end`|
| `temporal` | `description` | Notes | string | Notes about this date's association with the object | | `present_at/subject_of`&lt;br /&gt;(`classified_as aat:300411780`)|
| `` | `acknowledgement` | Credit line | string | Statement to display acknowledging the donor of the object | | `referred_to_by`&lt;br /&gt;(`classified_as aat:300026687`)|
| `` | `location` | Exhibit | string | The gallery at the NMA that the object is on display at | `Landmarks: People and Places across Australia gallery` | `used_for/took_place_at/label`&lt;br /&gt;(`classified_as aat:300054766`)|
| `` | `isPartOf` | Parent record | integer | The parent object that this object is part of | | `part_of`|
| `` | `hasPart` | Child record | integer | Child objects that are parts of this object | | `part`|
| `relation` | `id` | Related object record number | integer | NMA EMu Catalogue record number for the related object | | `relation`|
| `relation` | `type` | Related object type | string | API entity type for the related object | `object` | ``|
| `relation` | `title` | Related object title | string | The title of the related object | | ``|
| `seeAlso` | `type` | Web link type | string | API entity type for the web link | `Link` | ``|
| `seeAlso` | `title` | Web link label | string | Label for the web link | | ``|
| `seeAlso` | `identifier` | Web link URL | string | URL to any related links or references | | `seeAlso/identified_by`&lt;br /&gt;(`classified_as aat:300264578`)|
| `hasVersion` | `id` | Media record number | integer | NMA EMu Catalogue record number for the media | | `representation`|
| `hasVersion` | `type` | Media type | string | API entity type for the media | `StillImage` | ``|
| `hasVersion` | `rights` | Copyright status of media URI | string | URI for the rights or licence for media representations of the object | `https://creativecommons.org/licenses/by-nc-sa/4.0/` &lt;br /&gt;`http://rightsstatements.org/vocab/InC/1.0/` | `aggregates/subject_to/component`|
| `hasVersion` | `rightsTitle` | Copyright status of media | string | Label for the rights or licence for media representations of the object | `Public Domain` &lt;br /&gt;`CC BY-SA 4.0` &lt;br /&gt;`CC BY-NC-SA 4.0` &lt;br /&gt;`Copyright not evaluated` &lt;br /&gt;`Copyright undetermined` &lt;br /&gt;`All Rights Reserved` | `aggregates/subject_to/component`|
| `hasVersion` | `rightsReason` | Reason for copyright restriction | string |  | | `aggregates/subject_to/subject_of`&lt;br /&gt;(`classified_as aat:300404457`)|
| `hasVersion/hasVersion` | `type` | Media type | string | API entity type for the media file | `StillImage` | ``|
| `hasVersion/hasVersion` | `version` | Media version | string | Version of the media file | `thumbnail image` &lt;br /&gt;`preview image` | ``|
| `hasVersion/hasVersion` | `identifier` | Media location | string | URL to retrieve the media file | | `representation/representation/about`|
| `_meta` | `modified` | Last modified | date | Date the record was last modified in Emu | `2018-03-26` | `documented_in/modified`|
| `_meta` | `issued` | Web release date | date | Date the record was released to NMA's Collection Explorer website | `2008-10-01` | `documented_in/issued`|
| `_meta` | `hasFormat` | Collection Explorer link | string | URL to view the object in NMA's Collection Explorer website | `http://collectionsearch.nma.gov.au/object/64620` | `subject_of`&lt;br /&gt;(`classified_as aat:300264578`)|
| `_meta` | `copyright` | Record data copyright | string | Copyright statement for the metadata record | `Copyright National Museum of Australia / CC BY-NC` | `-`|
| `_meta` | `licence` | Record data licence | string | Licence URI for the metadata record | `https://creativecommons.org/licenses/by-nc/4.0/` | `-`|
</c:result>
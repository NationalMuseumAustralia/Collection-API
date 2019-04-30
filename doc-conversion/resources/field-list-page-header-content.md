<a id="records"></a>
# API records

Museum content records (from the `/object` and `/narrative` API endpoints) include enough details for the basic display of collection items and their images, creators, names, places, etc. If you need more details you can make extra calls to the other endpoints.

#### Museum content

| API endpoint | Description | Entity type |
| ------------ | ----------- | ----------- |
| [`/object`](https://data.nma.gov.au/object?title=*) | The museum catalogue plus images/media | `object` |
| [`/narrative`](https://data.nma.gov.au/narrative?title=*) | Narratives by Museum staff about featured topics | `narrative` |

#### Details of related entities

| API endpoint | Description | Entity type |
| ------------ | ----------- | -------- |
| [`/party`](https://data.nma.gov.au/party?name=*) | People and organisations associated with collection items | `party` |
| [`/place`](https://data.nma.gov.au/place?title=*) | Locations associated with collection items | `place` |
| [`/collection`](https://data.nma.gov.au/collection?title=*) | Sub-collections within the museum catalogue | `collection` |
| [`/media`](https://data.nma.gov.au/media?id=*) | Images and other media associated with collection items | `StillImage` |

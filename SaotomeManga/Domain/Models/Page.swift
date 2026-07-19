/// Página genérica de un listado paginado (contrato: MangaPageDTO / AuthorPageDTO).
struct Page<Item: Sendable & Equatable>: Equatable {
    let items: [Item]
    let metadata: PageMetadata
}

/// Metadatos de paginación (contrato: PageMetadataDTO — `per` se modela como `itemsPerPage`).
struct PageMetadata: Equatable {
    let page: Int
    let itemsPerPage: Int
    let total: Int
}

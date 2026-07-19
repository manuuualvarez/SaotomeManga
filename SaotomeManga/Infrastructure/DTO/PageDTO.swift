/// Página genérica del wire-format (contrato: MangaPageDTO / AuthorPageDTO).
struct PageDTO<Item: Decodable & Sendable>: Decodable {
    let items: [Item]
    let metadata: PageMetadataDTO
}

/// Metadatos de paginación del wire-format (contrato: PageMetadataDTO).
struct PageMetadataDTO: Decodable {
    let page: Int
    let per: Int
    let total: Int
}

typealias MangaPageDTO = PageDTO<MangaDTO>
typealias AuthorPageDTO = PageDTO<AuthorDTO>

extension PageMetadataDTO {
    func toDomain() -> PageMetadata {
        PageMetadata(page: page, itemsPerPage: per, total: total)
    }
}

extension PageDTO<MangaDTO> {
    func toDomain() throws(DomainError) -> Page<Manga> {
        // Bucle explícito: el `map` rethrows borra el tipo de error y rompe throws(DomainError).
        var mapped: [Manga] = []
        mapped.reserveCapacity(items.count)
        for item in items {
            try mapped.append(item.toDomain())
        }
        return Page(items: mapped, metadata: metadata.toDomain())
    }
}

extension PageDTO<AuthorDTO> {
    func toDomain() -> Page<Author> {
        Page(items: items.map { $0.toDomain() }, metadata: metadata.toDomain())
    }
}

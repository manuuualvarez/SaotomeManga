// Archivo temporal para verificar que la CI bloquea en rojo (01-T005). Se elimina tras la prueba.
enum CIRedProbe {
    static func forcedCast(_ value: Any) -> String {
        value as! String
    }
}

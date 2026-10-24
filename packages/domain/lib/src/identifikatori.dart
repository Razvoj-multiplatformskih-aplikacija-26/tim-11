/// Identifikator predmeta, npr. `p-1`.
/// Poseban tip umesto golog String-a: kompajler ne dozvoljava da se
/// id predmeta prosledi tamo gde se ocekuje id zakupa.
extension type const PredmetId(String value) {}

/// Identifikator zakupa, npr. `z-1`.
extension type const ZakupId(String value) {}
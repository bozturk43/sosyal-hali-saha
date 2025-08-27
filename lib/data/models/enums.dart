// Bu enum, oyuncu mevkilerini temsil eder.
// Enhanced enum kullanarak, her bir mevkiye karşılık gelen
// ve Strapi'nin beklediği String değerini de saklıyoruz.
enum PlayerPosition {
  kaleci('Kaleci'),
  defans('Defans'),
  ortaSaha('Orta Saha'),
  forvet('Forvet');

  const PlayerPosition(this.value);
  final String value;
}

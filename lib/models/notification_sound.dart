/// Configuration d'un thème de notification sonore : le fichier audio
/// composite à jouer (bips + son de fin), et l'offset auquel le son de
/// fin ("GO") démarre à l'intérieur de ce fichier. C'est cet offset,
/// retranché du temps restant réel au moment où on arme la notification,
/// qui détermine quand démarrer la lecture pour que le GO tombe pile à
/// la fin naturelle de l'étape.
///
/// Un seul thème existe pour l'instant ([classic]) ; la structure est
/// prévue pour en accueillir d'autres plus tard sans changer l'API du
/// service de notification ni de SessionController — il suffira
/// d'ajouter une autre constante ici, puis (plus tard, volontairement
/// hors périmètre pour l'instant) une interface pour en choisir un.
class NotificationSound {
  final String sequenceAsset;
  final Duration goOffset;

  const NotificationSound({
    required this.sequenceAsset,
    required this.goOffset,
  });

  /// Séquence "3, 2, 1, GO" classique : fichier composite de 3 secondes
  /// (bip 3 : 0,0-0,8s ; bip 2 : 0,8-1,6s ; bip 1 : 1,6-2,4s ; GO :
  /// 2,4-3,0s), à copier dans `assets/sounds/reptimerSequence-3s.ogg`.
  static const classic = NotificationSound(
    sequenceAsset: 'sounds/reptimerSequence-3s.ogg',
    goOffset: Duration(milliseconds: 2400),
  );
}

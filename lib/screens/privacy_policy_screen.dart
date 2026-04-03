import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart' show kFontSerif, kFontSans;
import '../widgets/dot_grid_background.dart';

/// Privacy policy page accessible from the landing footer.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    _Section(
      'Introducció',
      "Benvingut/da a la política de privacitat d'Entrevista't. Ens comprometem "
          "a protegir la teva privacitat i a tractar les teves dades personals "
          "amb la màxima cura i transparència. Aquesta política descriu quines "
          "dades recopilem, com les utilitzem i quins drets tens com a usuari.",
    ),
    _Section(
      'Dades que recopilem',
      "Quan utilitzes la nostra plataforma, podem recopilar les següents dades:\n\n"
          "• Informació del compte: nom, adreça electrònica i contrasenya.\n"
          "• Dades d'ús: registres de sessions d'entrevista, puntuacions i mètriques de rendiment.\n"
          "• Dades tècniques: adreça IP, tipus de navegador, sistema operatiu i dispositiu.\n"
          "• Contingut de les sessions: àudio i vídeo capturats durant les entrevistes simulades, "
          "processats en temps real i no emmagatzemats permanentment.",
    ),
    _Section(
      'Com utilitzem les teves dades',
      "Les dades recollides s'utilitzen exclusivament per:\n\n"
          "• Proporcionar i millorar el servei d'entrevistes simulades.\n"
          "• Generar informes de rendiment personalitzats (PDF).\n"
          "• Analitzar mètriques de veu, expressió facial i contacte visual.\n"
          "• Enviar comunicacions relacionades amb el servei (si ho has autoritzat).\n"
          "• Garantir la seguretat i el funcionament correcte de la plataforma.",
    ),
    _Section(
      'Base legal del tractament',
      "El tractament de les teves dades es basa en:\n\n"
          "• El teu consentiment explícit en registrar-te i utilitzar la plataforma.\n"
          "• L'execució del contracte de servei entre tu i Entrevista't.\n"
          "• El compliment d'obligacions legals aplicables.\n"
          "• L'interès legítim en millorar els nostres serveis, sempre respectant els teus drets.",
    ),
    _Section(
      'Conservació de les dades',
      "Conservem les teves dades personals únicament durant el temps necessari "
          "per complir les finalitats descrites en aquesta política. Les gravacions "
          "d'àudio i vídeo es processen en temps real i no s'emmagatzemen de "
          "forma permanent als nostres servidors. Les dades del compte i els "
          "informes es conserven mentre mantinguis el compte actiu.",
    ),
    _Section(
      'Compartició amb tercers',
      "No venem, lloguem ni compartim les teves dades personals amb tercers "
          "amb finalitats comercials. Podem compartir dades únicament amb:\n\n"
          "• Proveïdors de serveis tècnics necessaris per al funcionament de la plataforma.\n"
          "• Autoritats competents quan sigui requerit per llei.\n\n"
          "Tots els proveïdors estan subjectes a acords de confidencialitat i "
          "protecció de dades.",
    ),
    _Section(
      'Els teus drets',
      "D'acord amb el Reglament General de Protecció de Dades (RGPD), tens dret a:\n\n"
          "• Accedir a les teves dades personals.\n"
          "• Rectificar dades inexactes o incompletes.\n"
          "• Sol·licitar la supressió de les teves dades.\n"
          "• Oposar-te al tractament o sol·licitar-ne la limitació.\n"
          "• La portabilitat de les teves dades.\n"
          "• Retirar el consentiment en qualsevol moment.\n\n"
          "Per exercir qualsevol d'aquests drets, pots contactar-nos a través "
          "dels canals indicats a la secció de contacte.",
    ),
    _Section(
      'Seguretat',
      "Implementem mesures tècniques i organitzatives adequades per protegir "
          "les teves dades contra l'accés no autoritzat, la pèrdua, la destrucció "
          "o l'alteració. Això inclou xifratge de dades en trànsit, controls "
          "d'accés restringits i auditories periòdiques de seguretat.",
    ),
    _Section(
      'Canvis en aquesta política',
      "Ens reservem el dret de modificar aquesta política de privacitat en "
          "qualsevol moment. Qualsevol canvi significatiu serà comunicat a "
          "través de la plataforma o per correu electrònic. T'animem a revisar "
          "aquesta pàgina periòdicament.",
    ),
    _Section(
      'Contacte',
      "Si tens qualsevol pregunta o dubte sobre aquesta política de privacitat "
          "o sobre el tractament de les teves dades, pots contactar-nos a:\n\n"
          "• Correu electrònic: privacitat@entrevistat.cat\n"
          "• GitHub: github.com/Entrevista-t",
    ),
  ];

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _stagger;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  // +1 for the header
  static final _totalItems = PrivacyPolicyScreen._sections.length + 1;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnims = List.generate(_totalItems, (i) {
      final s = (i * 0.08).clamp(0.0, 0.75);
      final e = (s + 0.25).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _stagger,
        curve: Interval(s, e, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_totalItems, (i) {
      final s = (i * 0.08).clamp(0.0, 0.75);
      final e = (s + 0.25).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _stagger,
        curve: Interval(s, e, curve: Curves.easeOut),
      ));
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  void _playEntrance() {
    if (!_stagger.isAnimating && _stagger.value == 0) {
      _stagger.forward();
    }
  }

  Widget _anim(int i, Widget child) => SlideTransition(
        position: _slideAnims[i],
        child: FadeTransition(opacity: _fadeAnims[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _playEntrance());

    final sections = PrivacyPolicyScreen._sections;

    return Scaffold(
      body: DotGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: kPagePadding, vertical: kS12),
                child: Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.go('/landing'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 18,
                              color: context.colors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Entrevista't",
                              style: TextStyle(
                                fontFamily: kFontSerif,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable content ─────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: kS32, bottom: kS48),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: kPagePadding),
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(maxWidth: 720),
                          child: Column(
                            children: [
                              // ── Header ─────────────────────────────
                              _anim(
                                0,
                                Column(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                      decoration: BoxDecoration(
                                        color: kAccent.withValues(
                                            alpha: 0.10),
                                        borderRadius:
                                            BorderRadius.circular(
                                                kRadiusFull),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          Icon(
                                              Icons.shield_outlined,
                                              size: 14,
                                              color: kAccent),
                                          const SizedBox(width: 6),
                                          Text(
                                            'PRIVACITAT',
                                            style: TextStyle(
                                              fontFamily: kFontSans,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: kAccent,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: kS16),
                                    Text(
                                      'Política de privacitat',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: kFontSerif,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w500,
                                        color: context
                                            .colors.textPrimary,
                                        letterSpacing: -0.3,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: kS12),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(
                                              maxWidth: 480),
                                      child: Text(
                                        'Com recopilem, utilitzem i protegim '
                                        'les teves dades personals.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: kFontSans,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: context
                                              .colors.textSecondary,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: kS8),
                                    Text(
                                      'Última actualització: abril 2026',
                                      style: TextStyle(
                                        fontFamily: kFontSans,
                                        fontSize: 13,
                                        color: context
                                            .colors.textTertiary,
                                      ),
                                    ),
                                    const SizedBox(height: kS32),
                                  ],
                                ),
                              ),

                              // ── Section cards ─────────────────────
                              ...List.generate(
                                  sections.length, (i) {
                                final s = sections[i];
                                return _anim(
                                  i + 1,
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: kS12),
                                    child: Container(
                                      width: double.infinity,
                                      padding:
                                          const EdgeInsets.all(kS20),
                                      decoration: BoxDecoration(
                                        color:
                                            context.colors.bgSurface,
                                        borderRadius:
                                            BorderRadius.circular(
                                                kRadiusMd),
                                        border: Border.all(
                                            color: context
                                                .colors.borderSubtle),
                                        boxShadow: kShadowSm,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.title,
                                            style: TextStyle(
                                              fontFamily: kFontSans,
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: context.colors
                                                  .textPrimary,
                                              height: 1.4,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: kS12),
                                          Text(
                                            s.body,
                                            style: TextStyle(
                                              fontFamily: kFontSans,
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w400,
                                              color: context.colors
                                                  .textSecondary,
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                              const SizedBox(height: kS16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

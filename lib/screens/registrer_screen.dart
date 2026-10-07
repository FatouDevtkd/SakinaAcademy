import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

const sakinaGreen = Color(0xFF112623);
const sakinaGreenLight = Color(0xFF1E3A36);
const sakinaGreenDark = Color(0xFF0C1A18);
const sakinaMint = Color(0xFFE6F4F1);
const sakinaOutline = Color(0xFFB7CFCB);

final phoneSignupInProgress = ValueNotifier<bool>(false);

class SakinaLogo extends StatelessWidget {
  final double size;

  const SakinaLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'sakina-logo',
      child: Image.asset(
        'assets/images/logo.jpg',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.school, size: size, color: Colors.grey),
      ),
    );
  }
}

PreferredSizeWidget buildSakinaAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    titleSpacing: 12,
    title: Row(
      children: [
        const SakinaLogo(size: 28),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
    actions: actions,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sakinaGreen, sakinaGreenDark],
        ),
      ),
    ),
  );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneCodeController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLogin = true;
  bool _usePhone = false;
  bool _registerWithPhone = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _codeSent = false;
  String _phoneNumber = '';
  String? _verificationId;
  ConfirmationResult? _webConfirmationResult;

  @override
  void initState() {
    super.initState();
    _auth.setLanguageCode('fr');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(const AssetImage('assets/images/logo.jpg'), context);
      }
    });
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun compte trouvé avec ces identifiants.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Identifiants incorrects. Vérifiez vos informations.';
      case 'phone-number-already-exists':
        return 'Un compte existe déjà avec ce numéro.';
      case 'email-already-in-use':
        return 'Cet e-mail appartient déjà à un compte. Connectez-vous à ce compte ; l’association du téléphone existant devra être effectuée séparément.';
      case 'credential-already-in-use':
        return 'Ce numéro est déjà associé à un autre compte.';
      case 'invalid-phone-number':
        return 'Le numéro de téléphone est invalide.';
      case 'invalid-verification-code':
        return 'Le code SMS est incorrect.';
      case 'invalid-verification-id':
      case 'session-expired':
        return 'Le code a expiré. Demandez un nouveau code.';
      case 'captcha-check-failed':
        return 'La vérification anti-robot a échoué. Réessayez.';
      case 'quota-exceeded':
        return 'La limite d’envoi de SMS est atteinte. Réessayez plus tard.';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion n’est pas activée dans Firebase.';
      case 'configuration-not-found':
        return 'Firebase Authentication n’est pas configuré pour ce projet. Dans Firebase Console, ouvrez Authentication, démarrez la configuration, puis activez le fournisseur E-mail/Mot de passe.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Problème de connexion internet.';
      case 'weak-password':
        return 'Mot de passe trop faible (au moins 6 caractères).';
      default:
        return 'Erreur Firebase ${error.code} : ${error.message ?? 'aucun détail fourni par Firebase.'}';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetPhoneVerification() {
    _codeSent = false;
    _verificationId = null;
    _webConfirmationResult = null;
    _phoneCodeController.clear();
  }

  void _selectLoginMode(bool isLogin) {
    setState(() {
      _isLogin = isLogin;
      _usePhone = false;
      _registerWithPhone = false;
      _confirmPasswordController.clear();
      _resetPhoneVerification();
    });
    if (isLogin) phoneSignupInProgress.value = false;
  }

  void _selectMethod(bool usePhone) {
    setState(() {
      _usePhone = usePhone;
      _resetPhoneVerification();
    });
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showMessage(
          'Saisissez votre adresse e-mail pour réinitialiser le mot de passe.');
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      _showMessage('E-mail de réinitialisation envoyé.');
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage(
          'Impossible d’envoyer l’e-mail de réinitialisation : $error');
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_codeSent && !(_formKey.currentState?.validate() ?? false)) return;

    if (_codeSent) {
      await _verifyPhoneCode();
      return;
    }

    if (_isLogin && _usePhone || !_isLogin && _registerWithPhone) {
      await _requestPhoneCode();
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await credential.user?.sendEmailVerification();
        _showMessage(
          'Compte créé. Confirmez votre adresse avec le lien envoyé par e-mail avant de vous connecter comme administratrice.',
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Impossible de traiter la demande : $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestPhoneCode() async {
    setState(() => _loading = true);
    try {
      if (kIsWeb) {
        _webConfirmationResult =
            await _auth.signInWithPhoneNumber(_phoneNumber);
        if (!mounted) return;
        setState(() {
          _codeSent = true;
          _loading = false;
        });
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: _phoneNumber,
          verificationCompleted: (credential) {
            _completePhoneSignIn(credential);
          },
          verificationFailed: (error) {
            if (mounted) setState(() => _loading = false);
            _showMessage(_authErrorMessage(error));
          },
          codeSent: (verificationId, _) {
            if (!mounted) return;
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _loading = false;
            });
            _showMessage('Un code de vérification a été envoyé par SMS.');
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _verificationId = verificationId;
          },
        );
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Impossible d’envoyer le code SMS : $error');
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Future<void> _verifyPhoneCode() async {
    final code = _phoneCodeController.text.trim();
    if (code.length < 6) {
      _showMessage('Saisissez le code de vérification reçu par SMS.');
      return;
    }

    setState(() => _loading = true);
    if (!_isLogin) phoneSignupInProgress.value = true;
    try {
      final result = kIsWeb
          ? await _webConfirmationResult!.confirm(code)
          : await _auth.signInWithCredential(
              PhoneAuthProvider.credential(
                verificationId: _verificationId!,
                smsCode: code,
              ),
            );
      await _completePhoneAuth(result);
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Impossible de vérifier le code : $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completePhoneSignIn(PhoneAuthCredential credential) async {
    if (mounted) setState(() => _loading = true);
    if (!_isLogin) phoneSignupInProgress.value = true;
    try {
      final result = await _auth.signInWithCredential(credential);
      await _completePhoneAuth(result);
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (error) {
      _showMessage('Impossible de vérifier le numéro : $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completePhoneAuth(UserCredential result) async {
    if (_isLogin) {
      _showPhoneSuccess(result);
      return;
    }

    final user = result.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase n’a pas retourné le compte authentifié.',
      );
    }
    await user.linkWithCredential(
      EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
    await user.sendEmailVerification();
    _showMessage(
      'Compte créé. Votre téléphone est vérifié et un e-mail de vérification a été envoyé.',
    );
    phoneSignupInProgress.value = false;
  }

  void _showPhoneSuccess(UserCredential result) {
    final isNewUser = result.additionalUserInfo?.isNewUser ?? false;
    _showMessage(
      isNewUser
          ? 'Numéro vérifié. Votre compte Sakina Academy est créé.'
          : 'Connexion réussie.',
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Veuillez saisir votre e-mail.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Format d’e-mail invalide.';
    }
    return null;
  }

  String? _validatePhone(PhoneNumber? phone) {
    if (phone == null || phone.number.trim().isEmpty) {
      return 'Saisissez votre numéro de téléphone.';
    }
    try {
      phone.isValidNumber();
      _phoneNumber = phone.completeNumber;
      return null;
    } on Exception {
      return 'Numéro invalide pour le pays sélectionné.';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isLogin ? 'Connexion - Sakina Academy' : 'Créer un compte';

    return Scaffold(
      appBar: buildSakinaAppBar(title),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0, -1.1),
                end: Alignment(0, 0.1),
                colors: [sakinaMint, Colors.transparent],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: sakinaOutline),
                      boxShadow: [
                        BoxShadow(
                          color: sakinaGreen.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SakinaLogo(size: 56),
                          const SizedBox(height: 12),
                          Text(
                            'Sakina Academy',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: sakinaGreenDark,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('Connexion'),
                                icon: Icon(Icons.login),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('Inscription'),
                                icon: Icon(Icons.person_add_alt_1),
                              ),
                            ],
                            selected: {_isLogin},
                            onSelectionChanged: _loading || _codeSent
                                ? null
                                : (selection) =>
                                    _selectLoginMode(selection.first),
                          ),
                          const SizedBox(height: 16),
                          if (!_isLogin)
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Par e-mail'),
                                  icon: Icon(Icons.email_outlined),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('E-mail + téléphone'),
                                  icon: Icon(Icons.phone_outlined),
                                ),
                              ],
                              selected: {_registerWithPhone},
                              onSelectionChanged: _loading || _codeSent
                                  ? null
                                  : (selection) => setState(
                                        () =>
                                            _registerWithPhone =
                                                selection.first,
                                      ),
                            ),
                          if (!_isLogin) const SizedBox(height: 16),
                          if (_isLogin)
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('E-mail'),
                                  icon: Icon(Icons.email_outlined),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Téléphone'),
                                  icon: Icon(Icons.phone_outlined),
                                ),
                              ],
                              selected: {_usePhone},
                              onSelectionChanged: _loading || _codeSent
                                  ? null
                                  : (selection) =>
                                      _selectMethod(selection.first),
                            ),
                          if (_isLogin) const SizedBox(height: 16),
                          if (!_isLogin || !_usePhone) ...[
                            TextFormField(
                              controller: _emailController,
                              enabled: !_codeSent,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Adresse e-mail',
                                prefixIcon: Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: _validateEmail,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _passwordController,
                              enabled: !_codeSent,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: IconButton(
                                  tooltip:
                                      _obscurePassword ? 'Afficher' : 'Masquer',
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) {
                                  return 'Veuillez saisir votre mot de passe.';
                                }
                                if (!_isLogin && value!.length < 6) {
                                  return 'Au moins 6 caractères.';
                                }
                                return null;
                              },
                              textInputAction: _isLogin
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              onFieldSubmitted: (_) {
                                if (_isLogin) _submit();
                              },
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _confirmPasswordController,
                                enabled: !_codeSent,
                                obscureText: _obscureConfirmation,
                                decoration: InputDecoration(
                                  labelText: 'Confirmer le mot de passe',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirmation
                                        ? 'Afficher'
                                        : 'Masquer',
                                    icon: Icon(
                                      _obscureConfirmation
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirmation =
                                          !_obscureConfirmation,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Veuillez confirmer le mot de passe.';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Les mots de passe ne correspondent pas.';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                            ],
                            if (_isLogin && _usePhone ||
                                !_isLogin && _registerWithPhone) ...[
                              const SizedBox(height: 10),
                              IntlPhoneField(
                                key:
                                    const ValueKey('international-phone-field'),
                                initialCountryCode: 'FR',
                                languageCode: 'fr',
                                enabled: !_codeSent,
                                disableLengthCheck: true,
                                decoration: const InputDecoration(
                                  labelText: 'Numéro de téléphone',
                                  hintText:
                                      'Choisissez le pays et saisissez le numéro',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: _validatePhone,
                                onChanged: (phone) {
                                  _phoneNumber = phone.completeNumber;
                                },
                              ),
                            ],
                            if (_codeSent) ...[
                              TextFormField(
                                controller: _phoneCodeController,
                                keyboardType: TextInputType.number,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode
                                ],
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  labelText: 'Code reçu par SMS',
                                  prefixIcon: Icon(Icons.sms_outlined),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => setState(
                                              _resetPhoneVerification,
                                            ),
                                    child: const Text('Modifier le numéro'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _loading ? null : _requestPhoneCode,
                                    child: const Text('Renvoyer le code'),
                                  ),
                                ],
                              ),
                            ] else if (_isLogin && _usePhone ||
                                !_isLogin && _registerWithPhone)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Choisissez votre pays pour ajouter son indicatif. À l’inscription, le téléphone et l’e-mail seront associés au même compte.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _submit,
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _isLogin && _usePhone ||
                                              !_isLogin &&
                                                  _registerWithPhone
                                          ? (_codeSent
                                              ? Icons.verified_user_outlined
                                              : Icons.sms_outlined)
                                          : (_isLogin
                                              ? Icons.login
                                              : Icons.person_add_alt_1),
                                    ),
                              label: Text(
                                _loading
                                    ? 'Veuillez patienter…'
                                    : (_isLogin && _usePhone ||
                                            !_isLogin &&
                                                _registerWithPhone)
                                        ? (_codeSent
                                            ? (_isLogin
                                                ? 'Vérifier le code'
                                                : 'Valider et créer mon compte')
                                            : (_isLogin
                                                ? 'Envoyer un code SMS'
                                                : 'Vérifier le téléphone'))
                                        : (_isLogin
                                            ? 'Se connecter'
                                            : 'S’inscrire'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: sakinaGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_isLogin && !_usePhone)
                            TextButton(
                              onPressed: _loading ? null : _resetPassword,
                              child: const Text('Mot de passe oublié ?'),
                            ),
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
    );
  }
}

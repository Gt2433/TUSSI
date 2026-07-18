import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { fr, en, ar, es }

class LanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.fr; // الفرنسية هي اللغة الأساسية للتطبيق (French as base language)

  AppLanguage get language => _language;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('app_language');
      if (langCode != null) {
        if (langCode == 'fr') {
          _language = AppLanguage.fr;
        } else if (langCode == 'en') {
          _language = AppLanguage.en;
        } else if (langCode == 'ar') {
          _language = AppLanguage.ar;
        } else if (langCode == 'es') {
          _language = AppLanguage.es;
        }
        notifyListeners();
      }
    } catch (_) {
      // Ignore
    }
  }

  Future<void> saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageCode);
    } catch (_) {
      // Ignore
    }
  }

  String get languageCode {
    switch (_language) {
      case AppLanguage.fr:
        return 'fr';
      case AppLanguage.en:
        return 'en';
      case AppLanguage.ar:
        return 'ar';
      case AppLanguage.es:
        return 'es';
    }
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  String translate(String key) {
    return _localizedValues[key]?[_language] ?? key;
  }

  // ─── Dictionary ───────────────────────────────────────────────
  static final Map<String, Map<AppLanguage, String>> _localizedValues = {
    'select_image_source': {
      AppLanguage.fr: 'Choisir la source de l\'image',
      AppLanguage.en: 'Select Image Source',
      AppLanguage.ar: 'اختر مصدر الصورة',
      AppLanguage.es: 'Seleccionar fuente de imagen',
    },
    'camera': {
      AppLanguage.fr: 'Appareil photo',
      AppLanguage.en: 'Camera',
      AppLanguage.ar: 'الكاميرا',
      AppLanguage.es: 'Cámara',
    },
    'gallery': {
      AppLanguage.fr: 'Galerie',
      AppLanguage.en: 'Gallery',
      AppLanguage.ar: 'المعرض',
      AppLanguage.es: 'Galería',
    },
    'crop_photo': {
      AppLanguage.fr: 'Ajuster la photo',
      AppLanguage.en: 'Adjust Photo',
      AppLanguage.ar: 'تعديل الصورة',
      AppLanguage.es: 'Ajustar foto',
    },
    'crop_instructions': {
      AppLanguage.fr: 'Pincez pour zoomer et faites glisser pour cadrer',
      AppLanguage.en: 'Pinch to zoom and drag to frame',
      AppLanguage.ar: 'قرص للتكبير واسحب للتأطير',
      AppLanguage.es: 'Pellizca para hacer zoom y arrastra para encuadrar',
    },
    'save': {
      AppLanguage.fr: 'Enregistrer',
      AppLanguage.en: 'Save',
      AppLanguage.ar: 'حفظ',
      AppLanguage.es: 'Guardar',
    },
    'save_settings': {
      AppLanguage.fr: 'Enregistrer les paramètres',
      AppLanguage.en: 'Save Settings',
      AppLanguage.ar: 'حفظ الإعدادات',
      AppLanguage.es: 'Guardar configuración',
    },
    'settings_saved': {
      AppLanguage.fr: 'Paramètres enregistrés avec succès ✓',
      AppLanguage.en: 'Settings saved successfully ✓',
      AppLanguage.ar: 'تم حفظ الإعدادات بنجاح ✓',
      AppLanguage.es: 'Configuración guardada correctamente ✓',
    },
    // Navigation / Tabs
    'tab_orders': {
      AppLanguage.fr: 'Commandes',
      AppLanguage.en: 'Orders',
      AppLanguage.ar: 'الطلبيات',
      AppLanguage.es: 'Pedidos',
    },
    'tab_new_order': {
      AppLanguage.fr: 'Nouvelle Commande',
      AppLanguage.en: 'New Order',
      AppLanguage.ar: 'طلب جديد',
      AppLanguage.es: 'Nuevo pedido',
    },
    'tab_history': {
      AppLanguage.fr: 'Historique',
      AppLanguage.en: 'History',
      AppLanguage.ar: 'السجل',
      AppLanguage.es: 'Historial',
    },
    'tab_profile': {
      AppLanguage.fr: 'Profil',
      AppLanguage.en: 'Profile',
      AppLanguage.ar: 'الملف الشخصي',
      AppLanguage.es: 'Perfil',
    },

    // Dialogs / Popups
    'sign_out': {
      AppLanguage.fr: 'Déconnexion',
      AppLanguage.en: 'Sign Out',
      AppLanguage.ar: 'تسجيل الخروج',
      AppLanguage.es: 'Cerrar sesión',
    },
    'sign_out_confirm': {
      AppLanguage.fr: 'Voulez-vous vous déconnecter?',
      AppLanguage.en: 'Do you want to sign out?',
      AppLanguage.ar: 'هل تريد تسجيل الخروج؟',
      AppLanguage.es: '¿Quieres cerrar sesión?',
    },
    'cancel': {
      AppLanguage.fr: 'Annuler',
      AppLanguage.en: 'Cancel',
      AppLanguage.ar: 'إلغاء',
      AppLanguage.es: 'Cancelar',
    },
    'logout': {
      AppLanguage.fr: 'Sortie',
      AppLanguage.en: 'Logout',
      AppLanguage.ar: 'خروج',
      AppLanguage.es: 'Cerrar sesión',
    },
    'warning': {
      AppLanguage.fr: 'Avertissement',
      AppLanguage.en: 'Warning',
      AppLanguage.ar: 'تحذير',
      AppLanguage.es: 'Advertencia',
    },

    // Profile Screen
    'user_account': {
      AppLanguage.fr: 'Compte Utilisateur',
      AppLanguage.en: 'User Account',
      AppLanguage.ar: 'حساب المستخدم',
      AppLanguage.es: 'Cuenta de usuario',
    },
    'full_name': {
      AppLanguage.fr: 'Nom complet',
      AppLanguage.en: 'Full Name',
      AppLanguage.ar: 'الاسم بالكامل',
      AppLanguage.es: 'Nombre completo',
    },
    'email': {
      AppLanguage.fr: 'E-mail',
      AppLanguage.en: 'Email',
      AppLanguage.ar: 'البريد الإلكتروني',
      AppLanguage.es: 'Correo electrónico',
    },
    'password': {
      AppLanguage.fr: 'Mot de passe',
      AppLanguage.en: 'Password',
      AppLanguage.ar: 'كلمة المرور',
      AppLanguage.es: 'Contraseña',
    },
    'settings': {
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
      AppLanguage.ar: 'الإعدادات',
      AppLanguage.es: 'Configuración',
    },
    'lang_and_theme': {
      AppLanguage.fr: 'Langue & Thème',
      AppLanguage.en: 'Language & Theme',
      AppLanguage.ar: 'اللغة والمظهر',
      AppLanguage.es: 'Idioma y tema',
    },
    'delete_account': {
      AppLanguage.fr: 'Supprimer le compte définitivement',
      AppLanguage.en: 'Delete Account Permanently',
      AppLanguage.ar: 'حذف الحساب نهائياً',
      AppLanguage.es: 'Eliminar cuenta permanentemente',
    },
    'delete_account_confirm': {
      AppLanguage.fr: 'Êtes-vous sûr de vouloir supprimer votre compte définitivement?',
      AppLanguage.en: 'Are you absolutely sure you want to delete your account?',
      AppLanguage.ar: 'هل أنت متأكد تماماً من حذف حسابك؟',
      AppLanguage.es: '¿Estás seguro de que quieres eliminar tu cuenta permanentemente?',
    },
    'delete_account_warn': {
      AppLanguage.fr: 'Attention: Cette action supprimera définitivement toutes vos données personnelles et votre compte de la base de données.',
      AppLanguage.en: 'Warning: This action will permanently delete all your personal data and account from the database.',
      AppLanguage.ar: 'تحذير: هذا الإجراء سيؤدي إلى حذف جميع بياناتك الشخصية وحسابك نهائياً من قاعدة البيانات ولا يمكن استرجاعها.',
      AppLanguage.es: 'Advertencia: Esta acción eliminará permanentemente todos tus datos personales y tu cuenta de la base de datos.',
    },
    'yes_delete': {
      AppLanguage.fr: 'Oui, supprimer définitivement',
      AppLanguage.en: 'Yes, delete permanently',
      AppLanguage.ar: 'نعم، احذف نهائياً',
      AppLanguage.es: 'Sí, eliminar permanentemente',
    },
    'delete_success': {
      AppLanguage.fr: 'Compte supprimé définitivement.',
      AppLanguage.en: 'Account deleted permanently.',
      AppLanguage.ar: 'تم حذف حسابك نهائياً بنجاح.',
      AppLanguage.es: 'Cuenta eliminada permanentemente.',
    },
    'delete_failed': {
      AppLanguage.fr: 'Échec de la suppression du compte.',
      AppLanguage.en: 'Failed to delete account.',
      AppLanguage.ar: 'فشل في حذف الحساب.',
      AppLanguage.es: 'Error al eliminar la cuenta.',
    },
    'photo_update_success': {
      AppLanguage.fr: 'Photo de profil mise à jour avec succès ✓',
      AppLanguage.en: 'Profile photo updated successfully ✓',
      AppLanguage.ar: 'تم تحديث صورة الملف الشخصي بنجاح ✓',
      AppLanguage.es: 'Foto de perfil actualizada correctamente ✓',
    },
    'photo_update_failed': {
      AppLanguage.fr: 'Échec de la mise à jour de la photo',
      AppLanguage.en: 'Photo update failed',
      AppLanguage.ar: 'فشل تحديث الصورة',
      AppLanguage.es: 'Error al actualizar la foto',
    },

    // Login / Register Screen
    'login': {
      AppLanguage.fr: 'Se connecter',
      AppLanguage.en: 'Sign In',
      AppLanguage.ar: 'تسجيل الدخول',
      AppLanguage.es: 'Iniciar sesión',
    },
    'create_account': {
      AppLanguage.fr: 'Créer un compte',
      AppLanguage.en: 'Create Account',
      AppLanguage.ar: 'إنشاء حساب جديد',
      AppLanguage.es: 'Crear cuenta',
    },
    'enter_email': {
      AppLanguage.fr: "Saisir l'e-mail",
      AppLanguage.en: 'Enter email',
      AppLanguage.ar: 'أدخل البريد الإلكتروني',
      AppLanguage.es: 'Ingresar correo electrónico',
    },
    'enter_password': {
      AppLanguage.fr: 'Saisir le mot de passe',
      AppLanguage.en: 'Enter password',
      AppLanguage.ar: 'أدخل كلمة المرور',
      AppLanguage.es: 'Ingresar contraseña',
    },
    'enter_name': {
      AppLanguage.fr: 'Saisir le nom',
      AppLanguage.en: 'Enter name',
      AppLanguage.ar: 'أدخل الاسم',
      AppLanguage.es: 'Ingresar nombre',
    },
    'required_email': {
      AppLanguage.fr: "Veuillez saisir l'e-mail",
      AppLanguage.en: 'Please enter email',
      AppLanguage.ar: 'الرجاء إدخال البريد الإلكتروني',
      AppLanguage.es: 'Por favor ingrese el correo electrónico',
    },
    'required_password': {
      AppLanguage.fr: 'Veuillez saisir le mot de passe',
      AppLanguage.en: 'Please enter password',
      AppLanguage.ar: 'الرجاء إدخال كلمة المرور',
      AppLanguage.es: 'Por favor ingrese la contraseña',
    },
    'weak_password': {
      AppLanguage.fr: 'Le mot de passe doit contenir au moins 6 caractères',
      AppLanguage.en: 'Password must be at least 6 characters',
      AppLanguage.ar: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      AppLanguage.es: 'La contraseña debe tener al menos 6 caracteres',
    },
    'required_name': {
      AppLanguage.fr: 'Veuillez saisir le nom complet',
      AppLanguage.en: 'Please enter full name',
      AppLanguage.ar: 'الرجاء إدخال الاسم بالكامل',
      AppLanguage.es: 'Por favor ingrese el nombre completo',
    },
    'already_have_account': {
      AppLanguage.fr: 'Déjà un compte? Se connecter',
      AppLanguage.en: 'Already have an account? Sign In',
      AppLanguage.ar: 'لديك حساب بالفعل؟ تسجيل الدخول',
      AppLanguage.es: '¿Ya tienes una cuenta? Iniciar sesión',
    },
    'dont_have_account': {
      AppLanguage.fr: 'Pas de compte? Créer un compte',
      AppLanguage.en: "Don't have an account? Sign Up",
      AppLanguage.ar: 'ليس لديك حساب؟ إنشاء حساب',
      AppLanguage.es: '¿No tienes una cuenta? Regístrate',
    },
    'register_btn': {
      AppLanguage.fr: "S'inscrire",
      AppLanguage.en: 'Register',
      AppLanguage.ar: 'إنشاء الحساب',
      AppLanguage.es: 'Registrarse',
    },

    // New Order Screen
    'new_order_instructions': {
      AppLanguage.fr: 'Choisissez le tissu, ajoutez les longueurs, puis envoyez',
      AppLanguage.en: 'Select fabric, add lengths, then send',
      AppLanguage.ar: 'اختر نوع القماش، أضف الأطوال، ثم أرسل الطلب',
      AppLanguage.es: 'Seleccione la tela, añada las longitudes y luego envíe',
    },
    'add_another_fabric': {
      AppLanguage.fr: 'Ajouter un autre tissu',
      AppLanguage.en: 'Add another fabric',
      AppLanguage.ar: 'إضافة قماش آخر',
      AppLanguage.es: 'Añadir otra tela',
    },
    'send_order': {
      AppLanguage.fr: 'Envoyer la commande',
      AppLanguage.en: 'Send Order',
      AppLanguage.ar: 'إرسال الطلب',
      AppLanguage.es: 'Enviar pedido',
    },
    'sending': {
      AppLanguage.fr: 'Envoi en cours...',
      AppLanguage.en: 'Sending...',
      AppLanguage.ar: 'جاري الإرسال...',
      AppLanguage.es: 'Enviando...',
    },
    'order_sent_to': {
      AppLanguage.fr: 'Commande envoyée à',
      AppLanguage.en: 'Order sent to',
      AppLanguage.ar: 'تم إرسال الطلب إلى',
      AppLanguage.es: 'Pedido enviado a',
    },
    'failed_send': {
      AppLanguage.fr: "Échec de l'envoi de la commande",
      AppLanguage.en: 'Failed to send order',
      AppLanguage.ar: 'فشل في إرسال الطلب',
      AppLanguage.es: 'Error al enviar el pedido',
    },

    // Fabric Entry Card
    'fabric': {
      AppLanguage.fr: 'Tissu',
      AppLanguage.en: 'Fabric',
      AppLanguage.ar: 'قماش',
      AppLanguage.es: 'Tela',
    },
    'fabric_type': {
      AppLanguage.fr: 'Type de tissu',
      AppLanguage.en: 'Fabric Type',
      AppLanguage.ar: 'نوع القماش',
      AppLanguage.es: 'Tipo de tela',
    },
    'select_fabric_type': {
      AppLanguage.fr: 'Choisir le type de tissu',
      AppLanguage.en: 'Select fabric type',
      AppLanguage.ar: 'اختر نوع القماش',
      AppLanguage.es: 'Seleccionar tipo de tela',
    },
    'meters_roll_length': {
      AppLanguage.fr: 'Mètres / Longueur du rouleau',
      AppLanguage.en: 'Meters / Roll Length',
      AppLanguage.ar: 'الأمتار / طول الأسطوانة',
      AppLanguage.es: 'Metros / Longitud del rollo',
    },
    'enter_length_hint': {
      AppLanguage.fr: 'Entrez la longueur (ex: 30)',
      AppLanguage.en: 'Enter length (e.g. 30)',
      AppLanguage.ar: 'أدخل الطول (مثلاً 30)',
      AppLanguage.es: 'Ingrese la longitud (ej: 30)',
    },
    'saved_lengths': {
      AppLanguage.fr: 'Longueurs enregistrées — Appuyez pour ajouter',
      AppLanguage.en: 'Saved lengths — Press to add',
      AppLanguage.ar: 'أطوال محفوظة — اضغط للإضافة',
      AppLanguage.es: 'Longitudes guardadas — Presione para añadir',
    },
    'write_length_quick': {
      AppLanguage.fr: "Saisir la longueur pour l'ajouter en raccourci",
      AppLanguage.en: 'Write length to add as quick button',
      AppLanguage.ar: 'اكتب طول لإضافته كزر سريع',
      AppLanguage.es: 'Escriba la longitud para añadir como botón rápido',
    },
    'selected_lengths': {
      AppLanguage.fr: 'Longueurs sélectionnées:',
      AppLanguage.en: 'Selected lengths:',
      AppLanguage.ar: 'الأطوال المختارة:',
      AppLanguage.es: 'Longitudes seleccionadas:',
    },
    'clear_lengths': {
      AppLanguage.fr: 'Vider les longueurs',
      AppLanguage.en: 'Clear lengths',
      AppLanguage.ar: 'تفريغ الأطوال',
      AppLanguage.es: 'Borrar longitudes',
    },
    'add_new_fabric_type': {
      AppLanguage.fr: 'Ajouter un nouveau type de tissu',
      AppLanguage.en: 'Add new fabric type',
      AppLanguage.ar: 'إضافة نوع قماش جديد',
      AppLanguage.es: 'Añadir nuevo tipo de tela',
    },
    'fabric_type_name': {
      AppLanguage.fr: 'Nom du type de tissu',
      AppLanguage.en: 'Fabric type name',
      AppLanguage.ar: 'اسم نوع القماش',
      AppLanguage.es: 'Nombre del tipo de tela',
    },
    'add': {
      AppLanguage.fr: 'Ajouter',
      AppLanguage.en: 'Add',
      AppLanguage.ar: 'إضافة',
      AppLanguage.es: 'Añadir',
    },
    'valid_positive_number': {
      AppLanguage.fr: 'Veuillez entrer un nombre positif valide',
      AppLanguage.en: 'Please enter a valid positive number',
      AppLanguage.ar: 'الرجاء إدخال رقم موجب صحيح',
      AppLanguage.es: 'Por favor ingrese un número positivo válido',
    },

    // Order Card / Orders Screen
    'from': {
      AppLanguage.fr: 'De:',
      AppLanguage.en: 'From:',
      AppLanguage.ar: 'من:',
      AppLanguage.es: 'De:',
    },
    'to': {
      AppLanguage.fr: 'À:',
      AppLanguage.en: 'To:',
      AppLanguage.ar: 'إلى:',
      AppLanguage.es: 'A:',
    },
    'done_btn': {
      AppLanguage.fr: 'Terminé  Done',
      AppLanguage.en: 'Done',
      AppLanguage.ar: 'تم  Done',
      AppLanguage.es: 'Listo  Done',
    },
    'completed': {
      AppLanguage.fr: 'Terminé ✓',
      AppLanguage.en: 'Completed ✓',
      AppLanguage.ar: 'تم ✓',
      AppLanguage.es: 'Completado ✓',
    },
    'pending': {
      AppLanguage.fr: 'En attente',
      AppLanguage.en: 'Pending',
      AppLanguage.ar: 'قيد الانتظار',
      AppLanguage.es: 'Pendiente',
    },
    'no_current_orders': {
      AppLanguage.fr: 'Aucune commande en cours',
      AppLanguage.en: 'No current orders',
      AppLanguage.ar: 'لا توجد طلبيات حالية',
      AppLanguage.es: 'No hay pedidos en curso',
    },
    'no_history_orders': {
      AppLanguage.fr: 'Aucun historique de commande',
      AppLanguage.en: 'No orders in history',
      AppLanguage.ar: 'لا توجد طلبيات في السجل',
      AppLanguage.es: 'No hay historial de pedidos',
    },
    'my_orders': {
      AppLanguage.fr: 'Mes commandes',
      AppLanguage.en: 'My orders',
      AppLanguage.ar: 'طلبياتي',
      AppLanguage.es: 'Mis pedidos',
    },
    'received_orders': {
      AppLanguage.fr: 'Commandes reçues',
      AppLanguage.en: 'Received orders',
      AppLanguage.ar: 'الطلبيات الواردة',
      AppLanguage.es: 'Pedidos recibidos',
    },
    'order_history': {
      AppLanguage.fr: 'Historique des commandes',
      AppLanguage.en: 'Order history',
      AppLanguage.ar: 'سجل الطلبيات',
      AppLanguage.es: 'Historial de pedidos',
    },

    // Send Order Dialog
    'send_order_to': {
      AppLanguage.fr: 'Envoyer la commande à',
      AppLanguage.en: 'Send order to',
      AppLanguage.ar: 'إرسال الطلب إلى',
      AppLanguage.es: 'Enviar pedido a',
    },
    'search_user': {
      AppLanguage.fr: 'Rechercher un utilisateur...',
      AppLanguage.en: 'Search user...',
      AppLanguage.ar: 'بحث عن مستخدم...',
      AppLanguage.es: 'Buscar usuario...',
    },
    'search_fabric': {
      AppLanguage.fr: 'Rechercher un tissu...',
      AppLanguage.en: 'Search fabric...',
      AppLanguage.ar: 'بحث عن قماش...',
      AppLanguage.es: 'Buscar tela...',
    },
    'total_price': {
      AppLanguage.fr: 'Prix total',
      AppLanguage.en: 'Total Price',
      AppLanguage.ar: 'إجمالي السعر',
      AppLanguage.es: 'Precio total',
    },
    'no_users_found': {
      AppLanguage.fr: 'Aucun utilisateur trouvé',
      AppLanguage.en: 'No users found',
      AppLanguage.ar: 'لم يتم العثور على مستخدمين',
      AppLanguage.es: 'No se encontraron usuarios',
    },
    'you': {
      AppLanguage.fr: 'Vous',
      AppLanguage.en: 'You',
      AppLanguage.ar: 'أنت',
      AppLanguage.es: 'Tú',
    },

    // Settings Screen
    'dark_mode': {
      AppLanguage.fr: 'Mode Sombre',
      AppLanguage.en: 'Dark Mode',
      AppLanguage.ar: 'المظهر الداكن',
      AppLanguage.es: 'Modo oscuro',
    },
    'enabled': {
      AppLanguage.fr: 'Activé',
      AppLanguage.en: 'Enabled',
      AppLanguage.ar: 'مفعّل',
      AppLanguage.es: 'Activado',
    },
    'disabled': {
      AppLanguage.fr: 'Désactivé',
      AppLanguage.en: 'Disabled',
      AppLanguage.ar: 'غير مفعّل',
      AppLanguage.es: 'Desactivado',
    },
    'language': {
      AppLanguage.fr: 'Langue',
      AppLanguage.en: 'Language',
      AppLanguage.ar: 'اللغة',
      AppLanguage.es: 'Idioma',
    },
    'select_language': {
      AppLanguage.fr: 'Choisir la langue',
      AppLanguage.en: 'Select Language',
      AppLanguage.ar: 'اختر اللغة',
      AppLanguage.es: 'Seleccionar idioma',
    },
    'app_settings': {
      AppLanguage.fr: 'Paramètres de l\'application',
      AppLanguage.en: 'App Settings',
      AppLanguage.ar: 'إعدادات التطبيق',
      AppLanguage.es: 'Configuración de la aplicación',
    },
    'unit_choice': {
      AppLanguage.fr: 'Unité de vente',
      AppLanguage.en: 'Selling Unit',
      AppLanguage.ar: 'وحدة البيع',
      AppLanguage.es: 'Unidad de venta',
    },
    'meter_label': {
      AppLanguage.fr: 'Mètre (m)',
      AppLanguage.en: 'Meter (m)',
      AppLanguage.ar: 'متر (m)',
      AppLanguage.es: 'Metro (m)',
    },
    'kg_label': {
      AppLanguage.fr: 'Kilogramme (kg)',
      AppLanguage.en: 'Kilogram (kg)',
      AppLanguage.ar: 'كيلو غرام (kg)',
      AppLanguage.es: 'Kilogramo (kg)',
    },
    'required_unit': {
      AppLanguage.fr: 'Veuillez choisir une unité de vente',
      AppLanguage.en: 'Please select a selling unit',
      AppLanguage.ar: 'الرجاء اختيار وحدة البيع',
      AppLanguage.es: 'Por favor seleccione una unidad de venta',
    },
    'fabric_name_required': {
      AppLanguage.fr: 'Veuillez entrer le nom du tissu',
      AppLanguage.en: 'Please enter fabric name',
      AppLanguage.ar: 'الرجاء إدخال اسم القماش',
      AppLanguage.es: 'Por favor ingrese el nombre de la tela',
    },
    'fabric_price': {
      AppLanguage.fr: 'Prix du tissu (DA)',
      AppLanguage.en: 'Fabric Price (DA)',
      AppLanguage.ar: 'سعر القماش (د.ج)',
      AppLanguage.es: 'Precio de la tela (DA)',
    },
    'fabric_price_required': {
      AppLanguage.fr: 'Veuillez entrer le prix du tissu',
      AppLanguage.en: 'Please enter fabric price',
      AppLanguage.ar: 'الرجاء إدخال سعر القماش',
      AppLanguage.es: 'Por favor ingrese el precio de la tela',
    },
    'invalid_price': {
      AppLanguage.fr: 'Veuillez entrer un prix valide',
      AppLanguage.en: 'Please enter a valid price',
      AppLanguage.ar: 'الرجاء إدخال سعر صحيح',
      AppLanguage.es: 'Por favor ingrese un precio válido',
    },
    'rolls_count': {
      AppLanguage.fr: 'Nombre de rouleaux',
      AppLanguage.en: 'Rolls Count',
      AppLanguage.ar: 'عدد الأسطوانات',
      AppLanguage.es: 'Cantidad de rollos',
    },
    'total_quantity': {
      AppLanguage.fr: 'Quantité totale',
      AppLanguage.en: 'Total Quantity',
      AppLanguage.ar: 'إجمالي الكمية',
      AppLanguage.es: 'Cantidad total',
    },
    'input_sequence': {
      AppLanguage.fr: 'Séquence de saisie',
      AppLanguage.en: 'Input Sequence',
      AppLanguage.ar: 'تسلسل الإدخال',
      AppLanguage.es: 'Secuencia de entrada',
    },
    'last_added': {
      AppLanguage.fr: 'Dernier',
      AppLanguage.en: 'Last',
      AppLanguage.ar: 'الأخير',
      AppLanguage.es: 'Último',
    },
    'kg_weight_roll': {
      AppLanguage.fr: 'Kilogrammes / Poids du rouleau',
      AppLanguage.en: 'Kilograms / Roll Weight',
      AppLanguage.ar: 'الكيلوغرامات / وزن الأسطوانة',
      AppLanguage.es: 'Kilogramos / Peso del rollo',
    },
    'enter_weight_hint': {
      AppLanguage.fr: 'Entrez le poids (ex: 30)',
      AppLanguage.en: 'Enter weight (e.g. 30)',
      AppLanguage.ar: 'أدخل الوزن (مثلاً 30)',
      AppLanguage.es: 'Ingrese el peso (ej: 30)',
    },
    'invalid_email': {
      AppLanguage.fr: 'Adresse e-mail invalide',
      AppLanguage.en: 'Invalid email address',
      AppLanguage.ar: 'البريد الإلكتروني غير صحيح',
      AppLanguage.es: 'Dirección de correo electrónico no válida',
    },
    'order_moved_to_history': {
      AppLanguage.fr: 'Commande déplacée vers l\'historique ✓',
      AppLanguage.en: 'Order moved to history ✓',
      AppLanguage.ar: 'تم نقل الطلب إلى السجل ✓',
      AppLanguage.es: 'Pedido movido al historial ✓',
    },
    'error_loading_orders': {
      AppLanguage.fr: 'Erreur lors du chargement des commandes',
      AppLanguage.en: 'Error loading orders',
      AppLanguage.ar: 'حدث خطأ في تحميل الطلبيات',
      AppLanguage.es: 'Error al cargar los pedidos',
    },
    'no_orders_yet': {
      AppLanguage.fr: 'Aucune commande pour le moment',
      AppLanguage.en: 'No orders at the moment',
      AppLanguage.ar: 'لا توجد طلبيات حالياً',
      AppLanguage.es: 'No hay pedidos en este momento',
    },
    'new_orders_appear_here': {
      AppLanguage.fr: 'Les nouvelles commandes apparaîtront ici automatiquement',
      AppLanguage.en: 'New orders will appear here automatically',
      AppLanguage.ar: 'الطلبيات الجديدة ستظهر هنا تلقائياً',
      AppLanguage.es: 'Los nuevos pedidos aparecerán aquí automáticamente',
    },
    'live': {
      AppLanguage.fr: 'En direct',
      AppLanguage.en: 'Live',
      AppLanguage.ar: 'مباشر',
      AppLanguage.es: 'En vivo',
    },
    'confirm_completion': {
      AppLanguage.fr: 'Confirmer la finalisation',
      AppLanguage.en: 'Confirm Completion',
      AppLanguage.ar: 'تأكيد الإنجاز',
      AppLanguage.es: 'Confirmar finalización',
    },
    'order_entered_question': {
      AppLanguage.fr: 'La commande a-t-elle été saisie dans le système principal ?',
      AppLanguage.en: 'Has the order been entered into the main system?',
      AppLanguage.ar: 'هل تم إدخال الطلب في النظام الرئيسي؟',
      AppLanguage.es: '¿Se ha ingresado el pedido en el sistema principal?',
    },
    'not_yet': {
      AppLanguage.fr: 'Pas encore',
      AppLanguage.en: 'Not yet',
      AppLanguage.ar: 'لا، بعد',
      AppLanguage.es: 'Aún no',
    },
    'yes_done': {
      AppLanguage.fr: 'Oui, fait ✓',
      AppLanguage.en: 'Yes, done ✓',
      AppLanguage.ar: 'نعم، تم ✓',
      AppLanguage.es: 'Sí, hecho ✓',
    },
    'expired_orders_deleted': {
      AppLanguage.fr: 'Commandes expirées supprimées',
      AppLanguage.en: 'Expired orders deleted',
      AppLanguage.ar: 'تم حذف طلبات منتهية الصلاحية',
      AppLanguage.es: 'Pedidos expirados eliminados',
    },
    'error_loading_history': {
      AppLanguage.fr: 'Erreur lors du chargement de l\'historique',
      AppLanguage.en: 'Error loading history',
      AppLanguage.ar: 'حدث خطأ في تحميل السجل',
      AppLanguage.es: 'Error al cargar el historial',
    },
    'no_history_yet': {
      AppLanguage.fr: 'Aucun historique',
      AppLanguage.en: 'No history',
      AppLanguage.ar: 'لا يوجد سجل طلبيات',
      AppLanguage.es: 'Sin historial',
    },
    'completed_orders_appear_here': {
      AppLanguage.fr: 'Les commandes terminées apparaîtront ici',
      AppLanguage.en: 'Completed orders will appear here',
      AppLanguage.ar: 'الطلبيات المنجزة ستظهر هنا',
      AppLanguage.es: 'Los pedidos completados aparecerán aquí',
    },
    'auto_delete_30_days': {
      AppLanguage.fr: 'Suppression automatique après 30 jours',
      AppLanguage.en: 'Auto delete after 30 days',
      AppLanguage.ar: 'حذف تلقائي بعد 30 يوم',
      AppLanguage.es: 'Eliminación automática después de 30 días',
    },
    'completed_orders_suffix': {
      AppLanguage.fr: 'commande(s) terminée(s)',
      AppLanguage.en: 'completed order(s)',
      AppLanguage.ar: 'طلب مكتمل',
      AppLanguage.es: 'pedido(s) completado(s)',
    },
    'orders_count_suffix': {
      AppLanguage.fr: 'commande(s)',
      AppLanguage.en: 'order(s)',
      AppLanguage.ar: 'طلب',
      AppLanguage.es: 'pedido(s)',
    },
    'tab_settings': {
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
      AppLanguage.ar: 'الإعدادات',
      AppLanguage.es: 'Configuración',
    },
    'order_sent_success': {
      AppLanguage.fr: 'Commande envoyée avec succès ✓',
      AppLanguage.en: 'Order sent successfully ✓',
      AppLanguage.ar: 'تم إرسال الطلب بنجاح ✓',
      AppLanguage.es: 'Pedido enviado correctamente ✓',
    },
    'edit_name': {
      AppLanguage.fr: 'Modifier le nom',
      AppLanguage.en: 'Edit Name',
      AppLanguage.ar: 'تعديل الاسم',
      AppLanguage.es: 'Editar nombre',
    },
    'enter_name': {
      AppLanguage.fr: 'Entrez le nouveau nom',
      AppLanguage.en: 'Enter new name',
      AppLanguage.ar: 'أدخل الاسم الجديد',
      AppLanguage.es: 'Ingrese el nuevo nombre',
    },
    'edit_password': {
      AppLanguage.fr: 'Modifier le mot de passe',
      AppLanguage.en: 'Change Password',
      AppLanguage.ar: 'تغيير كلمة المرور',
      AppLanguage.es: 'Cambiar contraseña',
    },
    'enter_new_password': {
      AppLanguage.fr: 'Entrez le nouveau mot de passe',
      AppLanguage.en: 'Enter new password',
      AppLanguage.ar: 'أدخل كلمة المرور الجديدة',
      AppLanguage.es: 'Ingrese la nueva contraseña',
    },
    'name_update_success': {
      AppLanguage.fr: 'Nom mis à jour avec succès',
      AppLanguage.en: 'Name updated successfully',
      AppLanguage.ar: 'تم تحديث الاسم بنجاح',
      AppLanguage.es: 'Nombre actualizado correctamente',
    },
    'password_update_success': {
      AppLanguage.fr: 'Mot de passe mis à jour avec succès',
      AppLanguage.en: 'Password updated successfully',
      AppLanguage.ar: 'تم تغيير كلمة المرور بنجاح',
      AppLanguage.es: 'Contraseña actualizada correctamente',
    },
  };
}

extension LocalizationExtension on BuildContext {
  String tr(String key) {
    try {
      final provider = Provider.of<LanguageProvider>(this, listen: true);
      return provider.translate(key);
    } catch (_) {
      // Return key as fallback if Provider is not active in context yet
      return key;
    }
  }
}

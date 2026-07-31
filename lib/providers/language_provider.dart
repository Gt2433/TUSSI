import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { fr, en, ar, es, zh }

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
        } else if (langCode == 'zh') {
          _language = AppLanguage.zh;
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
      case AppLanguage.zh:
        return 'zh';
    }
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  String translate(String key) {
    return _localizedValues[key]?[_language] ?? _localizedValues[key]?[AppLanguage.en] ?? key;
  }

  // ─── Dictionary ───────────────────────────────────────────────
  static final Map<String, Map<AppLanguage, String>> _localizedValues = {
    'select_image_source': {
      AppLanguage.fr: 'Choisir la source de l\'image',
      AppLanguage.en: 'Select Image Source',
      AppLanguage.ar: 'اختر مصدر الصورة',
      AppLanguage.es: 'Seleccionar fuente de imagen',
    
      AppLanguage.zh: '选择图片来源',},
    'camera': {
      AppLanguage.fr: 'Appareil photo',
      AppLanguage.en: 'Camera',
      AppLanguage.ar: 'الكاميرا',
      AppLanguage.es: 'Cámara',
    
      AppLanguage.zh: '相机',},
    'gallery': {
      AppLanguage.fr: 'Galerie',
      AppLanguage.en: 'Gallery',
      AppLanguage.ar: 'المعرض',
      AppLanguage.es: 'Galería',
    
      AppLanguage.zh: '相册',},
    'crop_photo': {
      AppLanguage.fr: 'Ajuster la photo',
      AppLanguage.en: 'Adjust Photo',
      AppLanguage.ar: 'تعديل الصورة',
      AppLanguage.es: 'Ajustar foto',
    
      AppLanguage.zh: '裁剪照片',},
    'crop_instructions': {
      AppLanguage.fr: 'Pincez pour zoomer et faites glisser pour cadrer',
      AppLanguage.en: 'Pinch to zoom and drag to frame',
      AppLanguage.ar: 'قرص للتكبير واسحب للتأطير',
      AppLanguage.es: 'Pellizca para hacer zoom y arrastra para encuadrar',
    
      AppLanguage.zh: '双指缩放并拖动以框选',},
    'save': {
      AppLanguage.fr: 'Enregistrer',
      AppLanguage.en: 'Save',
      AppLanguage.ar: 'حفظ',
      AppLanguage.es: 'Guardar',
    
      AppLanguage.zh: '保存',},
    'save_settings': {
      AppLanguage.fr: 'Enregistrer les paramètres',
      AppLanguage.en: 'Save Settings',
      AppLanguage.ar: 'حفظ الإعدادات',
      AppLanguage.es: 'Guardar configuración',
    
      AppLanguage.zh: '保存设置',},
    'settings_saved': {
      AppLanguage.fr: 'Paramètres enregistrés avec succès ✓',
      AppLanguage.en: 'Settings saved successfully ✓',
      AppLanguage.ar: 'تم حفظ الإعدادات بنجاح ✓',
      AppLanguage.es: 'Configuración guardada correctamente ✓',
    
      AppLanguage.zh: '设置保存成功 ✓',},
    // Navigation / Tabs
    'tab_orders': {
      AppLanguage.fr: 'Commandes',
      AppLanguage.en: 'Orders',
      AppLanguage.ar: 'الطلبيات',
      AppLanguage.es: 'Pedidos',
    
      AppLanguage.zh: '订单',},
    'tab_new_order': {
      AppLanguage.fr: 'Nouvelle Commande',
      AppLanguage.en: 'New Order',
      AppLanguage.ar: 'طلب جديد',
      AppLanguage.es: 'Nuevo pedido',
    
      AppLanguage.zh: '新订单',},
    'tab_history': {
      AppLanguage.fr: 'Historique',
      AppLanguage.en: 'History',
      AppLanguage.ar: 'السجل',
      AppLanguage.es: 'Historial',
    
      AppLanguage.zh: '历史记录',},
    'tab_profile': {
      AppLanguage.fr: 'Profil',
      AppLanguage.en: 'Profile',
      AppLanguage.ar: 'الملف الشخصي',
      AppLanguage.es: 'Perfil',
    
      AppLanguage.zh: '个人资料',},

    // Dialogs / Popups
    'sign_out': {
      AppLanguage.fr: 'Déconnexion',
      AppLanguage.en: 'Sign Out',
      AppLanguage.ar: 'تسجيل الخروج',
      AppLanguage.es: 'Cerrar sesión',
    
      AppLanguage.zh: '登出',},
    'sign_out_confirm': {
      AppLanguage.fr: 'Voulez-vous vous déconnecter?',
      AppLanguage.en: 'Do you want to sign out?',
      AppLanguage.ar: 'هل تريد تسجيل الخروج؟',
      AppLanguage.es: '¿Quieres cerrar sesión?',
    
      AppLanguage.zh: '您确定要登出吗？',},
    'cancel': {
      AppLanguage.fr: 'Annuler',
      AppLanguage.en: 'Cancel',
      AppLanguage.ar: 'إلغاء',
      AppLanguage.es: 'Cancelar',
    
      AppLanguage.zh: '取消',},
    'logout': {
      AppLanguage.fr: 'Sortie',
      AppLanguage.en: 'Logout',
      AppLanguage.ar: 'خروج',
      AppLanguage.es: 'Cerrar sesión',
    
      AppLanguage.zh: '注销',},
    'warning': {
      AppLanguage.fr: 'Avertissement',
      AppLanguage.en: 'Warning',
      AppLanguage.ar: 'تحذير',
      AppLanguage.es: 'Advertencia',
    
      AppLanguage.zh: '警告',},

    // Profile Screen
    'user_account': {
      AppLanguage.fr: 'Compte Utilisateur',
      AppLanguage.en: 'User Account',
      AppLanguage.ar: 'حساب المستخدم',
      AppLanguage.es: 'Cuenta de usuario',
    
      AppLanguage.zh: '用户账户',},
    'full_name': {
      AppLanguage.fr: 'Nom complet',
      AppLanguage.en: 'Full Name',
      AppLanguage.ar: 'الاسم بالكامل',
      AppLanguage.es: 'Nombre completo',
    
      AppLanguage.zh: '姓名',},
    'email': {
      AppLanguage.fr: 'E-mail',
      AppLanguage.en: 'Email',
      AppLanguage.ar: 'البريد الإلكتروني',
      AppLanguage.es: 'Correo electrónico',
    
      AppLanguage.zh: '电子邮件',},
    'password': {
      AppLanguage.fr: 'Mot de passe',
      AppLanguage.en: 'Password',
      AppLanguage.ar: 'كلمة المرور',
      AppLanguage.es: 'Contraseña',
    
      AppLanguage.zh: '密码',},
    'settings': {
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
      AppLanguage.ar: 'الإعدادات',
      AppLanguage.es: 'Configuración',
    
      AppLanguage.zh: '设置',},
    'lang_and_theme': {
      AppLanguage.fr: 'Langue & Thème',
      AppLanguage.en: 'Language & Theme',
      AppLanguage.ar: 'اللغة والمظهر',
      AppLanguage.es: 'Idioma y tema',
    
      AppLanguage.zh: '语言与主题',},
    'delete_account': {
      AppLanguage.fr: 'Supprimer le compte définitivement',
      AppLanguage.en: 'Delete Account Permanently',
      AppLanguage.ar: 'حذف الحساب نهائياً',
      AppLanguage.es: 'Eliminar cuenta permanentemente',
    
      AppLanguage.zh: '永久删除账户',},
    'delete_account_confirm': {
      AppLanguage.fr: 'Êtes-vous sûr de vouloir supprimer votre compte définitivement?',
      AppLanguage.en: 'Are you absolutely sure you want to delete your account?',
      AppLanguage.ar: 'هل أنت متأكد تماماً من حذف حسابك؟',
      AppLanguage.es: '¿Estás seguro de que quieres eliminar tu cuenta permanentemente?',
    
      AppLanguage.zh: '您绝对确定要永久删除您的账户吗？',},
    'delete_account_warn': {
      AppLanguage.fr: 'Attention: Cette action supprimera définitivement toutes vos données personnelles et votre compte de la base de données.',
      AppLanguage.en: 'Warning: This action will permanently delete all your personal data and account from the database.',
      AppLanguage.ar: 'تحذير: هذا الإجراء سيؤدي إلى حذف جميع بياناتك الشخصية وحسابك نهائياً من قاعدة البيانات ولا يمكن استرجاعها.',
      AppLanguage.es: 'Advertencia: Esta acción eliminará permanentemente todos tus datos personales y tu cuenta de la base de datos.',
    
      AppLanguage.zh: '警告：此操作将永久删除您的个人数据，且无法恢复。',},
    'yes_delete': {
      AppLanguage.fr: 'Oui, supprimer définitivement',
      AppLanguage.en: 'Yes, delete permanently',
      AppLanguage.ar: 'نعم، احذف نهائياً',
      AppLanguage.es: 'Sí, eliminar permanentemente',
    
      AppLanguage.zh: '是的，永久删除',},
    'delete_success': {
      AppLanguage.fr: 'Compte supprimé définitivement.',
      AppLanguage.en: 'Account deleted permanently.',
      AppLanguage.ar: 'تم حذف حسابك نهائياً بنجاح.',
      AppLanguage.es: 'Cuenta eliminada permanentemente.',
    
      AppLanguage.zh: '账户已成功删除。',},
    'delete_failed': {
      AppLanguage.fr: 'Échec de la suppression du compte.',
      AppLanguage.en: 'Failed to delete account.',
      AppLanguage.ar: 'فشل في حذف الحساب.',
      AppLanguage.es: 'Error al eliminar la cuenta.',
    
      AppLanguage.zh: '删除账户失败。',},
    'photo_update_success': {
      AppLanguage.fr: 'Photo de profil mise à jour avec succès ✓',
      AppLanguage.en: 'Profile photo updated successfully ✓',
      AppLanguage.ar: 'تم تحديث صورة الملف الشخصي بنجاح ✓',
      AppLanguage.es: 'Foto de perfil actualizada correctamente ✓',
    
      AppLanguage.zh: '头像更新成功 ✓',},
    'photo_update_failed': {
      AppLanguage.fr: 'Échec de la mise à jour de la photo',
      AppLanguage.en: 'Photo update failed',
      AppLanguage.ar: 'فشل تحديث الصورة',
      AppLanguage.es: 'Error al actualizar la foto',
    
      AppLanguage.zh: '头像更新失败',},

    // Login / Register Screen
    'login': {
      AppLanguage.fr: 'Se connecter',
      AppLanguage.en: 'Sign In',
      AppLanguage.ar: 'تسجيل الدخول',
      AppLanguage.es: 'Iniciar sesión',
    
      AppLanguage.zh: '登录',},
    'create_account': {
      AppLanguage.fr: 'Créer un compte',
      AppLanguage.en: 'Create Account',
      AppLanguage.ar: 'إنشاء حساب جديد',
      AppLanguage.es: 'Crear cuenta',
    
      AppLanguage.zh: '创建账户',},
    'enter_email': {
      AppLanguage.fr: "Saisir l'e-mail",
      AppLanguage.en: 'Enter email',
      AppLanguage.ar: 'أدخل البريد الإلكتروني',
      AppLanguage.es: 'Ingresar correo electrónico',
    
      AppLanguage.zh: '输入电子邮件',},
    'enter_password': {
      AppLanguage.fr: 'Saisir le mot de passe',
      AppLanguage.en: 'Enter password',
      AppLanguage.ar: 'أدخل كلمة المرور',
      AppLanguage.es: 'Ingresar contraseña',
    
      AppLanguage.zh: '输入密码',},
    'enter_name': {
      AppLanguage.fr: 'Saisir le nom',
      AppLanguage.en: 'Enter name',
      AppLanguage.ar: 'أدخل الاسم',
      AppLanguage.es: 'Ingresar nombre',
    
      AppLanguage.zh: '输入姓名',},
    'required_email': {
      AppLanguage.fr: "Veuillez saisir l'e-mail",
      AppLanguage.en: 'Please enter email',
      AppLanguage.ar: 'الرجاء إدخال البريد الإلكتروني',
      AppLanguage.es: 'Por favor ingrese el correo electrónico',
    
      AppLanguage.zh: '请输入电子邮件',},
    'required_password': {
      AppLanguage.fr: 'Veuillez saisir le mot de passe',
      AppLanguage.en: 'Please enter password',
      AppLanguage.ar: 'الرجاء إدخال كلمة المرور',
      AppLanguage.es: 'Por favor ingrese la contraseña',
    
      AppLanguage.zh: '请输入密码',},
    'weak_password': {
      AppLanguage.fr: 'Le mot de passe doit contenir au moins 6 caractères',
      AppLanguage.en: 'Password must be at least 6 characters',
      AppLanguage.ar: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      AppLanguage.es: 'La contraseña debe tener al menos 6 caracteres',
    
      AppLanguage.zh: '密码长度至少为 6 个字符',},
    'required_name': {
      AppLanguage.fr: 'Veuillez saisir le nom complet',
      AppLanguage.en: 'Please enter full name',
      AppLanguage.ar: 'الرجاء إدخال الاسم بالكامل',
      AppLanguage.es: 'Por favor ingrese el nombre completo',
    
      AppLanguage.zh: '请输入姓名',},
    'already_have_account': {
      AppLanguage.fr: 'Déjà un compte? Se connecter',
      AppLanguage.en: 'Already have an account? Sign In',
      AppLanguage.ar: 'لديك حساب بالفعل؟ تسجيل الدخول',
      AppLanguage.es: '¿Ya tienes una cuenta? Iniciar sesión',
    
      AppLanguage.zh: '已有账户？登录',},
    'dont_have_account': {
      AppLanguage.fr: 'Pas de compte? Créer un compte',
      AppLanguage.en: "Don't have an account? Sign Up",
      AppLanguage.ar: 'ليس لديك حساب؟ إنشاء حساب',
      AppLanguage.es: '¿No tienes una cuenta? Regístrate',
    
      AppLanguage.zh: '没有账户？注册',},
    'register_btn': {
      AppLanguage.fr: "S'inscrire",
      AppLanguage.en: 'Register',
      AppLanguage.ar: 'إنشاء الحساب',
      AppLanguage.es: 'Registrarse',
      AppLanguage.zh: '注册',
    },
    'welcome_choose_account_type': {
      AppLanguage.fr: 'Bienvenue! Choisissez le type de compte:',
      AppLanguage.en: 'Welcome! Choose account type:',
      AppLanguage.ar: 'مرحباً بك! اختر نوع الحساب:',
      AppLanguage.es: '¡Bienvenido! Elija el tipo de cuenta:',
      AppLanguage.zh: '欢迎！请选择账户类型：',
    },
    'create_new_shop': {
      AppLanguage.fr: '🏬 Créer une nouvelle boutique',
      AppLanguage.en: '🏬 Create New Shop',
      AppLanguage.ar: '🏬 إنشاء محل جديد',
      AppLanguage.es: '🏬 Crear nueva tienda',
      AppLanguage.zh: '🏬 创建新店铺',
    },
    'shop_owner_desc': {
      AppLanguage.fr: 'Je suis le propriétaire (Nommer la boutique & générer le code)',
      AppLanguage.en: 'I am shop owner (Name shop & generate code)',
      AppLanguage.ar: 'أنا صاحب المحل (سأقوم بتسمية محلي وتوليد كود لعمالي)',
      AppLanguage.es: 'Soy el propietario (Nombrar tienda y generar código)',
      AppLanguage.zh: '我是店主（命名店铺并生成代码）',
    },
    'join_existing_shop': {
      AppLanguage.fr: '🔗 Rejoindre une boutique existante',
      AppLanguage.en: '🔗 Join Existing Shop',
      AppLanguage.ar: '🔗 الانضمام لمحل موجود',
      AppLanguage.es: '🔗 Unirse a una tienda existente',
      AppLanguage.zh: '🔗 加入现有店铺',
    },
    'shop_worker_desc': {
      AppLanguage.fr: "Je suis employé / caissier (J'ai un code d'accès)",
      AppLanguage.en: 'I am worker / cashier (I have join code)',
      AppLanguage.ar: 'أنا عامل / كاشير (لدي كود انضمام تم تزويدي به)',
      AppLanguage.es: 'Soy empleado / cajero (Tengo código de acceso)',
      AppLanguage.zh: '我是店员 / 出纳（我有加入代码）',
    },
    'shop_name_label': {
      AppLanguage.fr: 'Nom de la boutique',
      AppLanguage.en: 'Shop Name',
      AppLanguage.ar: 'اسم المحل / تجارة',
      AppLanguage.es: 'Nombre de la tienda',
      AppLanguage.zh: '店铺名称',
    },
    'shop_code_label': {
      AppLanguage.fr: 'Code de la boutique',
      AppLanguage.en: 'Shop Code to Join',
      AppLanguage.ar: 'كود المحل للانضمام',
      AppLanguage.es: 'Código de la tienda',
      AppLanguage.zh: '要加入的店铺代码',
    },

    // New Order Screen
    'new_order_instructions': {
      AppLanguage.fr: 'Choisissez le tissu, ajoutez les longueurs, puis envoyez',
      AppLanguage.en: 'Select fabric, add lengths, then send',
      AppLanguage.ar: 'اختر نوع القماش، أضف الأطوال، ثم أرسل الطلب',
      AppLanguage.es: 'Seleccione la tela, añada las longitudes y luego envíe',
    
      AppLanguage.zh: '选择面料，输入长度，然后发送',},
    'add_another_fabric': {
      AppLanguage.fr: 'Ajouter un autre tissu',
      AppLanguage.en: 'Add another fabric',
      AppLanguage.ar: 'إضافة قماش آخر',
      AppLanguage.es: 'Añadir otra tela',
    
      AppLanguage.zh: '添加其他面料',},
    'send_order': {
      AppLanguage.fr: 'Envoyer la commande',
      AppLanguage.en: 'Send Order',
      AppLanguage.ar: 'إرسال الطلب',
      AppLanguage.es: 'Enviar pedido',
    
      AppLanguage.zh: '发送订单',},
    'sending': {
      AppLanguage.fr: 'Envoi en cours...',
      AppLanguage.en: 'Sending...',
      AppLanguage.ar: 'جاري الإرسال...',
      AppLanguage.es: 'Enviando...',
    
      AppLanguage.zh: '发送中...',},
    'order_sent_to': {
      AppLanguage.fr: 'Commande envoyée à',
      AppLanguage.en: 'Order sent to',
      AppLanguage.ar: 'تم إرسال الطلب إلى',
      AppLanguage.es: 'Pedido enviado a',
    
      AppLanguage.zh: '订单已发送至',},
    'failed_send': {
      AppLanguage.fr: "Échec de l'envoi de la commande",
      AppLanguage.en: 'Failed to send order',
      AppLanguage.ar: 'فشل في إرسال الطلب',
      AppLanguage.es: 'Error al enviar el pedido',
    
      AppLanguage.zh: '发送订单失败',},

    // Fabric Entry Card
    'fabric': {
      AppLanguage.fr: 'Tissu',
      AppLanguage.en: 'Fabric',
      AppLanguage.ar: 'قماش',
      AppLanguage.es: 'Tela',
    
      AppLanguage.zh: '面料',},
    'fabric_type': {
      AppLanguage.fr: 'Type de tissu',
      AppLanguage.en: 'Fabric Type',
      AppLanguage.ar: 'نوع القماش',
      AppLanguage.es: 'Tipo de tela',
    
      AppLanguage.zh: '面料类型',},
    'select_fabric_type': {
      AppLanguage.fr: 'Choisir le type de tissu',
      AppLanguage.en: 'Select fabric type',
      AppLanguage.ar: 'اختر نوع القماش',
      AppLanguage.es: 'Seleccionar tipo de tela',
    
      AppLanguage.zh: '选择面料类型',},
    'meters_roll_length': {
      AppLanguage.fr: 'Mètres / Longueur du rouleau',
      AppLanguage.en: 'Meters / Roll Length',
      AppLanguage.ar: 'الأمتار / طول الأسطوانة',
      AppLanguage.es: 'Metros / Longitud del rollo',
    
      AppLanguage.zh: '米 / 卷长',},
    'yards_roll_length': {
      AppLanguage.fr: 'Yards / Longueur du rouleau',
      AppLanguage.en: 'Yards / Roll Length',
      AppLanguage.ar: 'اليارد / طول الأسطوانة',
      AppLanguage.es: 'Yardas / Longitud del rollo',
    
      AppLanguage.zh: '码 / 卷长',},
    'enter_length_hint': {
      AppLanguage.fr: 'Entrez la longueur (ex: 30)',
      AppLanguage.en: 'Enter length (e.g. 30)',
      AppLanguage.ar: 'أدخل الطول (مثلاً 30)',
      AppLanguage.es: 'Ingrese la longitud (ej: 30)',
    
      AppLanguage.zh: '输入长度 (例如: 30)',},
    'saved_lengths': {
      AppLanguage.fr: 'Longueurs enregistrées — Appuyez pour ajouter',
      AppLanguage.en: 'Saved lengths — Press to add',
      AppLanguage.ar: 'أطوال محفوظة — اضغط للإضافة',
      AppLanguage.es: 'Longitudes guardadas — Presione para añadir',
    
      AppLanguage.zh: '已保存的长度 — 点击添加',},
    'write_length_quick': {
      AppLanguage.fr: "Saisir la longueur pour l'ajouter en raccourci",
      AppLanguage.en: 'Write length to add as quick button',
      AppLanguage.ar: 'اكتب طول لإضافته كزر سريع',
      AppLanguage.es: 'Escriba la longitud para añadir como botón rápido',
    
      AppLanguage.zh: '输入长度以添加为快捷键',},
    'selected_lengths': {
      AppLanguage.fr: 'Longueurs sélectionnées:',
      AppLanguage.en: 'Selected lengths:',
      AppLanguage.ar: 'الأطوال المختارة:',
      AppLanguage.es: 'Longitudes seleccionadas:',
    
      AppLanguage.zh: '选定长度:',},
    'clear_lengths': {
      AppLanguage.fr: 'Vider les longueurs',
      AppLanguage.en: 'Clear lengths',
      AppLanguage.ar: 'تفريغ الأطوال',
      AppLanguage.es: 'Borrar longitudes',
    
      AppLanguage.zh: '清除长度',},
    'undo': {
      AppLanguage.fr: 'Annuler',
      AppLanguage.en: 'Undo',
      AppLanguage.ar: 'تراجع',
      AppLanguage.es: 'Deshacer',
    
      AppLanguage.zh: '撤销',},
    'restore_lengths': {
      AppLanguage.fr: 'Restaurer les longueurs',
      AppLanguage.en: 'Restore lengths',
      AppLanguage.ar: 'استرجاع الأمتار',
      AppLanguage.es: 'Restaurar longitudes',
    
      AppLanguage.zh: '恢复长度',},
    'lengths_cleared': {
      AppLanguage.fr: 'Longueurs effacées',
      AppLanguage.en: 'Lengths cleared',
      AppLanguage.ar: 'تم مسح الأمتار',
      AppLanguage.es: 'Longitudes borradas',
    
      AppLanguage.zh: '长度已清除',},
    'restore_lengths_hint': {
      AppLanguage.fr: 'Longueurs effacées par erreur? Appuyez sur restaurer pour réessayer',
      AppLanguage.en: 'Lengths cleared by mistake? Tap restore to try again',
      AppLanguage.ar: 'تم مسح الأمتار بالخطأ؟ اضغط استرجاع للمحاولة مجدداً',
      AppLanguage.es: '¿Longitudes borradas por error? Presione restaurar para intentar de nuevo',
    
      AppLanguage.zh: '不小心清除了长度？点击恢复重试',},
    'entry_deleted': {
      AppLanguage.fr: 'Article supprimé',
      AppLanguage.en: 'Item deleted',
      AppLanguage.ar: 'تم حذف الصنف',
      AppLanguage.es: 'Artículo eliminado',
    
      AppLanguage.zh: '项目已删除',},
    'add_new_fabric_type': {
      AppLanguage.fr: 'Ajouter un nouveau type de tissu',
      AppLanguage.en: 'Add new fabric type',
      AppLanguage.ar: 'إضافة نوع قماش جديد',
      AppLanguage.es: 'Añadir nuevo tipo de tela',
    
      AppLanguage.zh: '添加新面料类型',},
    'fabric_type_name': {
      AppLanguage.fr: 'Nom du type de tissu',
      AppLanguage.en: 'Fabric type name',
      AppLanguage.ar: 'اسم نوع القماش',
      AppLanguage.es: 'Nombre del tipo de tela',
    
      AppLanguage.zh: '面料类型名称',},
    'add': {
      AppLanguage.fr: 'Ajouter',
      AppLanguage.en: 'Add',
      AppLanguage.ar: 'إضافة',
      AppLanguage.es: 'Añadir',
    
      AppLanguage.zh: '添加',},
    'valid_positive_number': {
      AppLanguage.fr: 'Veuillez entrer un nombre positif valide',
      AppLanguage.en: 'Please enter a valid positive number',
      AppLanguage.ar: 'الرجاء إدخال رقم موجب صحيح',
      AppLanguage.es: 'Por favor ingrese un número positivo válido',
    
      AppLanguage.zh: '请输入有效的正数',},

    // Order Card / Orders Screen
    'from': {
      AppLanguage.fr: 'De:',
      AppLanguage.en: 'From:',
      AppLanguage.ar: 'من:',
      AppLanguage.es: 'De:',
    
      AppLanguage.zh: '来自:',},
    'to': {
      AppLanguage.fr: 'À:',
      AppLanguage.en: 'To:',
      AppLanguage.ar: 'إلى:',
      AppLanguage.es: 'A:',
    
      AppLanguage.zh: '收件人:',},
    'done_btn': {
      AppLanguage.fr: 'Terminé  Done',
      AppLanguage.en: 'Done',
      AppLanguage.ar: 'تم  Done',
      AppLanguage.es: 'Listo  Done',
    
      AppLanguage.zh: '完成',},
    'completed': {
      AppLanguage.fr: 'Terminé ✓',
      AppLanguage.en: 'Completed ✓',
      AppLanguage.ar: 'تم ✓',
      AppLanguage.es: 'Completado ✓',
    
      AppLanguage.zh: '已完成 ✓',},
    'pending': {
      AppLanguage.fr: 'En attente',
      AppLanguage.en: 'Pending',
      AppLanguage.ar: 'قيد الانتظار',
      AppLanguage.es: 'Pendiente',
    
      AppLanguage.zh: '等待中',},
    'no_current_orders': {
      AppLanguage.fr: 'Aucune commande en cours',
      AppLanguage.en: 'No current orders',
      AppLanguage.ar: 'لا توجد طلبيات حالية',
      AppLanguage.es: 'No hay pedidos en curso',
    
      AppLanguage.zh: '暂无当前订单',},
    'no_history_orders': {
      AppLanguage.fr: 'Aucun historique de commande',
      AppLanguage.en: 'No orders in history',
      AppLanguage.ar: 'لا توجد طلبيات في السجل',
      AppLanguage.es: 'No hay historial de pedidos',
    
      AppLanguage.zh: '历史记录中暂无订单',},
    'my_orders': {
      AppLanguage.fr: 'Mes commandes',
      AppLanguage.en: 'My orders',
      AppLanguage.ar: 'طلبياتي',
      AppLanguage.es: 'Mis pedidos',
    
      AppLanguage.zh: '我的订单',},
    'received_orders': {
      AppLanguage.fr: 'Commandes reçues',
      AppLanguage.en: 'Received orders',
      AppLanguage.ar: 'الطلبيات الواردة',
      AppLanguage.es: 'Pedidos recibidos',
    
      AppLanguage.zh: '收到的订单',},
    'order_history': {
      AppLanguage.fr: 'Historique des commandes',
      AppLanguage.en: 'Order history',
      AppLanguage.ar: 'سجل الطلبيات',
      AppLanguage.es: 'Historial de pedidos',
    
      AppLanguage.zh: '订单历史',},

    // Send Order Dialog
    'send_order_to': {
      AppLanguage.fr: 'Envoyer la commande à',
      AppLanguage.en: 'Send order to',
      AppLanguage.ar: 'إرسال الطلب إلى',
      AppLanguage.es: 'Enviar pedido a',
    
      AppLanguage.zh: '发送订单至',},
    'search_user': {
      AppLanguage.fr: 'Rechercher un utilisateur...',
      AppLanguage.en: 'Search user...',
      AppLanguage.ar: 'بحث عن مستخدم...',
      AppLanguage.es: 'Buscar usuario...',
    
      AppLanguage.zh: '搜索用户...',},
    'search_fabric': {
      AppLanguage.fr: 'Rechercher un tissu...',
      AppLanguage.en: 'Search fabric...',
      AppLanguage.ar: 'بحث عن قماش...',
      AppLanguage.es: 'Buscar tela...',
    
      AppLanguage.zh: '搜索面料...',},
    'total_price': {
      AppLanguage.fr: 'Prix total',
      AppLanguage.en: 'Total Price',
      AppLanguage.ar: 'إجمالي السعر',
      AppLanguage.es: 'Precio total',
    
      AppLanguage.zh: '总价',},
    'no_users_found': {
      AppLanguage.fr: 'Aucun utilisateur trouvé',
      AppLanguage.en: 'No users found',
      AppLanguage.ar: 'لم يتم العثور على مستخدمين',
      AppLanguage.es: 'No se encontraron usuarios',
    
      AppLanguage.zh: '未找到用户',},
    'you': {
      AppLanguage.fr: 'Vous',
      AppLanguage.en: 'You',
      AppLanguage.ar: 'أنت',
      AppLanguage.es: 'Tú',
    
      AppLanguage.zh: '您',},

    // Settings Screen
    'dark_mode': {
      AppLanguage.fr: 'Mode Sombre',
      AppLanguage.en: 'Dark Mode',
      AppLanguage.ar: 'المظهر الداكن',
      AppLanguage.es: 'Modo oscuro',
      AppLanguage.zh: '暗黑模式',
    },
    'enabled': {
      AppLanguage.fr: 'Activé',
      AppLanguage.en: 'Enabled',
      AppLanguage.ar: 'مفعّل',
      AppLanguage.es: 'Activado',
      AppLanguage.zh: '已启用',
    },
    'disabled': {
      AppLanguage.fr: 'Désactivé',
      AppLanguage.en: 'Disabled',
      AppLanguage.ar: 'غير مفعّل',
      AppLanguage.es: 'Desactivado',
      AppLanguage.zh: '已禁用',
    },
    'language': {
      AppLanguage.fr: 'Langue',
      AppLanguage.en: 'Language',
      AppLanguage.ar: 'اللغة',
      AppLanguage.es: 'Idioma',
      AppLanguage.zh: '语言',
    },
    'select_language': {
      AppLanguage.fr: 'Choisir la langue',
      AppLanguage.en: 'Select Language',
      AppLanguage.ar: 'اختر اللغة',
      AppLanguage.es: 'Seleccionar idioma',
      AppLanguage.zh: '选择语言',
    },
    'app_settings': {
      AppLanguage.fr: 'Paramètres de l\'application',
      AppLanguage.en: 'App Settings',
      AppLanguage.ar: 'إعدادات التطبيق',
      AppLanguage.es: 'Configuración de la aplicación',
    
      AppLanguage.zh: '应用设置',},
    'unit_choice': {
      AppLanguage.fr: 'Unité de vente',
      AppLanguage.en: 'Selling Unit',
      AppLanguage.ar: 'وحدة البيع',
      AppLanguage.es: 'Unidad de venta',
    
      AppLanguage.zh: '销售单位',},
    'meter_label': {
      AppLanguage.fr: 'Mètre (m)',
      AppLanguage.en: 'Meter (m)',
      AppLanguage.ar: 'متر (m)',
      AppLanguage.es: 'Metro (m)',
    
      AppLanguage.zh: '米 (m)',},
    'yard_label': {
      AppLanguage.fr: 'Yard (Y)',
      AppLanguage.en: 'Yard (Y)',
      AppLanguage.ar: 'يارد (Y)',
      AppLanguage.es: 'Yarda (Y)',
    
      AppLanguage.zh: '码 (Y)',},
    'kg_label': {
      AppLanguage.fr: 'Kilogramme (kg)',
      AppLanguage.en: 'Kilogram (kg)',
      AppLanguage.ar: 'كيلو غرام (kg)',
      AppLanguage.es: 'Kilogramo (kg)',
    
      AppLanguage.zh: '公斤 (kg)',},
    'required_unit': {
      AppLanguage.fr: 'Veuillez choisir une unité de vente',
      AppLanguage.en: 'Please select a selling unit',
      AppLanguage.ar: 'الرجاء اختيار وحدة البيع',
      AppLanguage.es: 'Por favor seleccione una unidad de venta',
    
      AppLanguage.zh: '请选择销售单位',},
    'fabric_name_required': {
      AppLanguage.fr: 'Veuillez entrer le nom du tissu',
      AppLanguage.en: 'Please enter fabric name',
      AppLanguage.ar: 'الرجاء إدخال اسم القماش',
      AppLanguage.es: 'Por favor ingrese el nombre de la tela',
    
      AppLanguage.zh: '请输入面料名称',},
    'fabric_price': {
      AppLanguage.fr: 'Prix du tissu (DA)',
      AppLanguage.en: 'Fabric Price (DA)',
      AppLanguage.ar: 'سعر القماش (د.ج)',
      AppLanguage.es: 'Precio de la tela (DA)',
    
      AppLanguage.zh: '面料价格 (DA)',},
    'fabric_price_required': {
      AppLanguage.fr: 'Veuillez entrer le prix du tissu',
      AppLanguage.en: 'Please enter fabric price',
      AppLanguage.ar: 'الرجاء إدخال سعر القماش',
      AppLanguage.es: 'Por favor ingrese el precio de la tela',
    
      AppLanguage.zh: '请输入面料价格',},
    'invalid_price': {
      AppLanguage.fr: 'Veuillez entrer un prix valide',
      AppLanguage.en: 'Please enter a valid price',
      AppLanguage.ar: 'الرجاء إدخال سعر صحيح',
      AppLanguage.es: 'Por favor ingrese un precio válido',
    
      AppLanguage.zh: '请输入有效的价格',},
    'rolls_count': {
      AppLanguage.fr: 'Nombre de rouleaux',
      AppLanguage.en: 'Rolls Count',
      AppLanguage.ar: 'عدد الأسطوانات',
      AppLanguage.es: 'Cantidad de rollos',
    
      AppLanguage.zh: '卷数',},
    'total_quantity': {
      AppLanguage.fr: 'Quantité totale',
      AppLanguage.en: 'Total Quantity',
      AppLanguage.ar: 'إجمالي الكمية',
      AppLanguage.es: 'Cantidad total',
    
      AppLanguage.zh: '总数量',},
    'input_sequence': {
      AppLanguage.fr: 'Séquence de saisie',
      AppLanguage.en: 'Input Sequence',
      AppLanguage.ar: 'تسلسل الإدخال',
      AppLanguage.es: 'Secuencia de entrada',
    
      AppLanguage.zh: '输入顺序',},
    'last_added': {
      AppLanguage.fr: 'Dernier',
      AppLanguage.en: 'Last',
      AppLanguage.ar: 'الأخير',
      AppLanguage.es: 'Último',
    
      AppLanguage.zh: '最后添加',},
    'kg_weight_roll': {
      AppLanguage.fr: 'Kilogrammes / Poids du rouleau',
      AppLanguage.en: 'Kilograms / Roll Weight',
      AppLanguage.ar: 'الكيلوغرامات / وزن الأسطوانة',
      AppLanguage.es: 'Kilogramos / Peso del rollo',
    
      AppLanguage.zh: '公斤 / 卷重',},
    'enter_weight_hint': {
      AppLanguage.fr: 'Entrez le poids (ex: 30)',
      AppLanguage.en: 'Enter weight (e.g. 30)',
      AppLanguage.ar: 'أدخل الوزن (مثلاً 30)',
      AppLanguage.es: 'Ingrese el peso (ej: 30)',
    
      AppLanguage.zh: '输入重量 (例如: 30)',},
    'invalid_email': {
      AppLanguage.fr: 'Adresse e-mail invalide',
      AppLanguage.en: 'Invalid email address',
      AppLanguage.ar: 'البريد الإلكتروني غير صحيح',
      AppLanguage.es: 'Dirección de correo electrónico no válida',
    
      AppLanguage.zh: '电子邮件地址无效',},
    'order_moved_to_history': {
      AppLanguage.fr: 'Commande déplacée vers l\'historique ✓',
      AppLanguage.en: 'Order moved to history ✓',
      AppLanguage.ar: 'تم نقل الطلب إلى السجل ✓',
      AppLanguage.es: 'Pedido movido al historial ✓',
    
      AppLanguage.zh: '订单已移至历史记录 ✓',},
    'error_loading_orders': {
      AppLanguage.fr: 'Erreur lors du chargement des commandes',
      AppLanguage.en: 'Error loading orders',
      AppLanguage.ar: 'حدث خطأ في تحميل الطلبيات',
      AppLanguage.es: 'Error al cargar los pedidos',
    
      AppLanguage.zh: '加载订单时出错',},
    'no_orders_yet': {
      AppLanguage.fr: 'Aucune commande pour le moment',
      AppLanguage.en: 'No orders at the moment',
      AppLanguage.ar: 'لا توجد طلبيات حالياً',
      AppLanguage.es: 'No hay pedidos en este momento',
    
      AppLanguage.zh: '目前暂无订单',},
    'new_orders_appear_here': {
      AppLanguage.fr: 'Les nouvelles commandes apparaîtront ici automatiquement',
      AppLanguage.en: 'New orders will appear here automatically',
      AppLanguage.ar: 'الطلبيات الجديدة ستظهر هنا تلقائياً',
      AppLanguage.es: 'Los nuevos pedidos aparecerán aquí automáticamente',
    
      AppLanguage.zh: '新订单将自动显示在此处',},
    'live': {
      AppLanguage.fr: 'En direct',
      AppLanguage.en: 'Live',
      AppLanguage.ar: 'مباشر',
      AppLanguage.es: 'En vivo',
    
      AppLanguage.zh: '实时',},
    'confirm_completion': {
      AppLanguage.fr: 'Confirmer la finalisation',
      AppLanguage.en: 'Confirm Completion',
      AppLanguage.ar: 'تأكيد الإنجاز',
      AppLanguage.es: 'Confirmar finalización',
    
      AppLanguage.zh: '确认完成',},
    'order_entered_question': {
      AppLanguage.fr: 'La commande a-t-elle été saisie dans le système principal ?',
      AppLanguage.en: 'Has the order been entered into the main system?',
      AppLanguage.ar: 'هل تم إدخال الطلب في النظام الرئيسي؟',
      AppLanguage.es: '¿Se ha ingresado el pedido en el sistema principal?',
    
      AppLanguage.zh: '订单是否已输入主系统？',},
    'not_yet': {
      AppLanguage.fr: 'Pas encore',
      AppLanguage.en: 'Not yet',
      AppLanguage.ar: 'لا، بعد',
      AppLanguage.es: 'Aún no',
    
      AppLanguage.zh: '尚未',},
    'yes_done': {
      AppLanguage.fr: 'Oui, fait ✓',
      AppLanguage.en: 'Yes, done ✓',
      AppLanguage.ar: 'نعم، تم ✓',
      AppLanguage.es: 'Sí, hecho ✓',
    
      AppLanguage.zh: '是的，已完成 ✓',},
    'expired_orders_deleted': {
      AppLanguage.fr: 'Commandes expirées supprimées',
      AppLanguage.en: 'Expired orders deleted',
      AppLanguage.ar: 'تم حذف طلبات منتهية الصلاحية',
      AppLanguage.es: 'Pedidos expirados eliminados',
    
      AppLanguage.zh: '已删除过期的订单',},
    'error_loading_history': {
      AppLanguage.fr: 'Erreur lors du chargement de l\'historique',
      AppLanguage.en: 'Error loading history',
      AppLanguage.ar: 'حدث خطأ في تحميل السجل',
      AppLanguage.es: 'Error al cargar el historial',
    
      AppLanguage.zh: '加载历史记录时出错',},
    'no_history_yet': {
      AppLanguage.fr: 'Aucun historique',
      AppLanguage.en: 'No history',
      AppLanguage.ar: 'لا يوجد سجل طلبيات',
      AppLanguage.es: 'Sin historial',
    
      AppLanguage.zh: '暂无历史记录',},
    'completed_orders_appear_here': {
      AppLanguage.fr: 'Les commandes terminées apparaîtront ici',
      AppLanguage.en: 'Completed orders will appear here',
      AppLanguage.ar: 'الطلبيات المنجزة ستظهر هنا',
      AppLanguage.es: 'Los pedidos completados aparecerán aquí',
    
      AppLanguage.zh: '已完成的订单将显示在此处',},
    'auto_delete_30_days': {
      AppLanguage.fr: 'Suppression automatique après 30 jours',
      AppLanguage.en: 'Auto delete after 30 days',
      AppLanguage.ar: 'حذف تلقائي بعد 30 يوم',
      AppLanguage.es: 'Eliminación automática después de 30 días',
    
      AppLanguage.zh: '30天后自动删除',},
    'completed_orders_suffix': {
      AppLanguage.fr: 'commande(s) terminée(s)',
      AppLanguage.en: 'completed order(s)',
      AppLanguage.ar: 'طلب مكتمل',
      AppLanguage.es: 'pedido(s) completado(s)',
    
      AppLanguage.zh: '个已完成订单',},
    'orders_count_suffix': {
      AppLanguage.fr: 'commande(s)',
      AppLanguage.en: 'order(s)',
      AppLanguage.ar: 'طلب',
      AppLanguage.es: 'pedido(s)',
    
      AppLanguage.zh: '个订单',},
    'tab_settings': {
      AppLanguage.fr: 'Paramètres',
      AppLanguage.en: 'Settings',
      AppLanguage.ar: 'الإعدادات',
      AppLanguage.es: 'Configuración',
    
      AppLanguage.zh: '设置',},
    'order_sent_success': {
      AppLanguage.fr: 'Commande envoyée avec succès ✓',
      AppLanguage.en: 'Order sent successfully ✓',
      AppLanguage.ar: 'تم إرسال الطلب بنجاح ✓',
      AppLanguage.es: 'Pedido enviado correctamente ✓',
    
      AppLanguage.zh: '订单发送成功 ✓',},
    'edit_name': {
      AppLanguage.fr: 'Modifier le nom',
      AppLanguage.en: 'Edit Name',
      AppLanguage.ar: 'تعديل الاسم',
      AppLanguage.es: 'Editar nombre',
    
      AppLanguage.zh: '修改姓名',},
    'enter_new_name': {
      AppLanguage.fr: 'Entrez le nouveau nom',
      AppLanguage.en: 'Enter new name',
      AppLanguage.ar: 'أدخل الاسم الجديد',
      AppLanguage.es: 'Ingrese el nuevo nombre',
      AppLanguage.zh: '输入姓名',
    },
    'edit_password': {
      AppLanguage.fr: 'Modifier le mot de passe',
      AppLanguage.en: 'Change Password',
      AppLanguage.ar: 'تغيير كلمة المرور',
      AppLanguage.es: 'Cambiar contraseña',
    
      AppLanguage.zh: '修改密码',},
    'enter_new_password': {
      AppLanguage.fr: 'Entrez le nouveau mot de passe',
      AppLanguage.en: 'Enter new password',
      AppLanguage.ar: 'أدخل كلمة المرور الجديدة',
      AppLanguage.es: 'Ingrese la nueva contraseña',
    
      AppLanguage.zh: '输入新密码',},
    'name_update_success': {
      AppLanguage.fr: 'Nom mis à jour avec succès',
      AppLanguage.en: 'Name updated successfully',
      AppLanguage.ar: 'تم تحديث الاسم بنجاح',
      AppLanguage.es: 'Nombre actualizado correctamente',
    
      AppLanguage.zh: '姓名更新成功',},
    'password_update_success': {
      AppLanguage.fr: 'Mot de passe mis à jour avec succès',
      AppLanguage.en: 'Password updated successfully',
      AppLanguage.ar: 'تم تغيير كلمة المرور بنجاح',
      AppLanguage.es: 'Contraseña actualizada correctamente',
    
      AppLanguage.zh: '密码更新成功',},
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

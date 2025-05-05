// Translations for maintenance page
export interface Translation {
  title: string;
  message: string;
  progress: string;
  apology: string;
  checkBack: string;
  contact: string;
  footer: string;
}

export const translations: Record<string, Translation> = {
  en: {
    title: "System Maintenance",
    message: "We're currently performing scheduled maintenance on our systems.",
    progress: "Our team is working diligently to complete the maintenance as quickly as possible.",
    apology: "We apologize for any inconvenience this may cause.",
    checkBack: "Please check back soon. We appreciate your patience.",
    contact: "If you need immediate assistance, please contact us at:",
    footer: "This site is temporarily unavailable due to planned maintenance."
  },
  es: {
    title: "Mantenimiento del Sistema",
    message: "Actualmente estamos realizando un mantenimiento programado en nuestros sistemas.",
    progress: "Nuestro equipo está trabajando diligentemente para completar el mantenimiento lo más rápido posible.",
    apology: "Pedimos disculpas por cualquier inconveniente que esto pueda causar.",
    checkBack: "Por favor, vuelva a consultar pronto. Agradecemos su paciencia.",
    contact: "Si necesita asistencia inmediata, contáctenos en:",
    footer: "Este sitio está temporalmente no disponible debido a un mantenimiento planificado."
  },
  fr: {
    title: "Maintenance du Système",
    message: "Nous effectuons actuellement une maintenance planifiée sur nos systèmes.",
    progress: "Notre équipe travaille avec diligence pour terminer la maintenance aussi rapidement que possible.",
    apology: "Nous nous excusons pour tout inconvénient que cela pourrait causer.",
    checkBack: "Veuillez revenir bientôt. Nous apprécions votre patience.",
    contact: "Si vous avez besoin d'une assistance immédiate, veuillez nous contacter à :",
    footer: "Ce site est temporairement indisponible en raison d'une maintenance planifiée."
  },
  de: {
    title: "Systemwartung",
    message: "Wir führen derzeit eine geplante Wartung unserer Systeme durch.",
    progress: "Unser Team arbeitet fleißig daran, die Wartung so schnell wie möglich abzuschließen.",
    apology: "Wir entschuldigen uns für eventuelle Unannehmlichkeiten, die dadurch entstehen könnten.",
    checkBack: "Bitte schauen Sie bald wieder vorbei. Wir danken für Ihre Geduld.",
    contact: "Wenn Sie sofortige Hilfe benötigen, kontaktieren Sie uns bitte unter:",
    footer: "Diese Website ist aufgrund geplanter Wartung vorübergehend nicht verfügbar."
  },
  it: {
    title: "Manutenzione del Sistema",
    message: "Stiamo attualmente eseguendo una manutenzione programmata sui nostri sistemi.",
    progress: "Il nostro team sta lavorando diligentemente per completare la manutenzione il più rapidamente possibile.",
    apology: "Ci scusiamo per eventuali disagi che questo potrebbe causare.",
    checkBack: "Si prega di tornare a controllare presto. Apprezziamo la vostra pazienza.",
    contact: "Se hai bisogno di assistenza immediata, contattaci a:",
    footer: "Questo sito è temporaneamente non disponibile a causa di una manutenzione pianificata."
  },
  pt: {
    title: "Manutenção do Sistema",
    message: "Estamos atualmente realizando uma manutenção programada em nossos sistemas.",
    progress: "Nossa equipe está trabalhando diligentemente para concluir a manutenção o mais rápido possível.",
    apology: "Pedimos desculpas por qualquer inconveniente que isso possa causar.",
    checkBack: "Por favor, volte em breve. Agradecemos sua paciência.",
    contact: "Se precisar de assistência imediata, entre em contato conosco em:",
    footer: "Este site está temporariamente indisponível devido à manutenção planejada."
  },
  ja: {
    title: "システムメンテナンス",
    message: "現在、システムの定期メンテナンスを実施しています。",
    progress: "私たちのチームは、可能な限り迅速にメンテナンスを完了させるために懸命に作業しています。",
    apology: "ご迷惑をおかけして申し訳ありません。",
    checkBack: "もうしばらくしてからアクセスしてください。ご理解とご協力に感謝いたします。",
    contact: "すぐにサポートが必要な場合は、以下までお問い合わせください：",
    footer: "このサイトは計画的なメンテナンスのため一時的に利用できません。"
  },
  zh: {
    title: "系统维护",
    message: "我们目前正在对系统进行计划维护。",
    progress: "我们的团队正在努力尽快完成维护工作。",
    apology: "对于由此可能造成的任何不便，我们深表歉意。",
    checkBack: "请稍后再来查看。感谢您的耐心等待。",
    contact: "如果您需要立即获得帮助，请通过以下方式联系我们：",
    footer: "由于计划维护，此网站暂时不可用。"
  },
  ru: {
    title: "Техническое обслуживание системы",
    message: "В настоящее время мы проводим плановое техническое обслуживание наших систем.",
    progress: "Наша команда усердно работает над тем, чтобы завершить техническое обслуживание как можно быстрее.",
    apology: "Приносим извинения за любые неудобства, которые это может вызвать.",
    checkBack: "Пожалуйста, проверьте позже. Мы ценим ваше терпение.",
    contact: "Если вам нужна немедленная помощь, свяжитесь с нами по адресу:",
    footer: "Этот сайт временно недоступен из-за планового технического обслуживания."
  }
};
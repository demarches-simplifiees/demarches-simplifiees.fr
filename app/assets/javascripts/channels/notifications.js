//App.messages = App.cable.subscriptions.create('NotificationsChannel', {
//    received: function (data) {
//        if (window.location.href.indexOf('backoffice') !== -1) {
//            $("#notification_alert").html(data['message']);
//
//            slideIn_notification_alert();
//        }
//    }
//});

function slideIn_notification_alert (){
    $("#notification_alert").animate({
        right: '20px'
    }, 250);

    setTimeout(slideOut_notification_alert, 3500);
}

function slideOut_notification_alert (){
    $("#notification_alert").animate({
        right: '-250px'
    }, 200);
}
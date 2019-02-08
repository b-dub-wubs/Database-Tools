

import smtplib

senderName = 'National Funding Reports'
sender = 'svc_reporter@nationalfunding.com'
# receivers = ['omouradi@nationalfunding.com']
# subject = 'SMTP e-mail test'
# messageBody = 'This is a test e-mail message.'

def sendEmail(receiversArr, subject, messageBody):
	message = ("From: %s <%s>\r\nTo: %s\r\nSubject: %s\r\n\r\n" % (senderName, sender, ', '.join(receivers), subject))
	message = message + messageBody

	try:
		smtpObj = smtplib.SMTP('10.0.0.198', '25')
		smtpObj.sendmail(sender, receivers, message)         
		print("Successfully sent email")
	except SMTPException:
		print("Error: unable to send email")


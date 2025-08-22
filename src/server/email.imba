# import dns from 'dns/promises'
# import { SMTPClient } from 'smtp-client'
# import crypto from 'crypto'
# import { DKIMSign } from 'dkim-signer'

# const { publicKey, privateKey } = crypto.generateKeyPairSync 'rsa', {
# 	modulusLength: 2048
# 	publicKeyEncoding: { type: 'spki', format: 'pem' }
# 	privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
# }

# def createDKIMHeader { domain, selector, privateKey, rfc822message }
# 	const dkimOptions = {
# 		domainName: domain
# 		keySelector: selector
# 		privateKey: privateKey
# 	}
# 	return DKIMSign(rfc822message, dkimOptions)

# def publishPublicKey { domain, selector, publicKey }
# 	const zoneId = 'TWÓJ_ZONE_ID'  # Z Cloudflare dashboard
# 	const apiToken = 'TWÓJ_API_TOKEN'  # Z Cloudflare API Tokens (uprawnienia DNS:Edit)
# 	const recordName = "{selector}._domainkey.{domain}"  # np. default._domainkey.quiz.com
# 	const recordContent = "v=DKIM1; k=rsa; p={publicKey.replace(/\n/g, '').replace(/-----BEGIN PUBLIC KEY-----/, '').replace(/-----END PUBLIC KEY-----/, '')}"  # Usuń nagłówki i nowe linie

# 	# Najpierw sprawdź, czy rekord istnieje (GET request)
# 	try
# 		const checkResponse = await fetch "https://api.cloudflare.com/client/v4/zones/{zoneId}/dns_records?type=TXT&name={recordName}", {
# 			method: 'GET'
# 			headers: {
# 				'Authorization': "Bearer {apiToken}"
# 				'Content-Type': 'application/json'
# 			}
# 		}
# 		const checkData = await checkResponse.json!
# 		if !checkData.success
# 			console.error 'Błąd sprawdzania rekordu:', checkData.errors
# 			return
# 		if checkData.result.length > 0
# 			console.log 'Rekord DKIM już istnieje dla {recordName}. Pomijam publikację.'
# 			return  # Kończymy, nie publikujemy
# 	catch err
# 		console.error 'Błąd połączenia podczas sprawdzania:', err
# 		return

# 	# Jeśli nie istnieje, publikujemy (POST)
# 	const record = {
# 		type: 'TXT'
# 		name: recordName
# 		content: recordContent
# 		ttl: 3600  # 1 godzina
# 		proxied: false
# 	}

# 	try
# 		const response = await fetch "https://api.cloudflare.com/client/v4/zones/{zoneId}/dns_records", {
# 			method: 'POST'
# 			headers: {
# 				'Authorization': "Bearer {apiToken}"
# 				'Content-Type': 'application/json'
# 			}
# 			body: JSON.stringify(record)
# 		}
# 		const data = await response.json!
# 		if data.success
# 			console.log 'Rekord DKIM opublikowany pomyślnie:', data.result
# 		else
# 			console.error 'Błąd publikacji:', data.errors
# 	catch err
# 		console.error 'Błąd połączenia podczas publikacji:', err

# def sendMail { from, to, subject, text }
# 	const recipientDomain = to.split('@')[1]
# 	const mxRecords = await dns.resolveMx recipientDomain
# 	mxRecords.sort do(a, b) a.priority - b.priority
# 	const mxHost = mxRecords[0].exchange
# 	const domain = from.split('@')[1]
# 	const headers = {
# 		from,
# 		to,
# 		subject,
# 		date: new Date().toUTCString()
# 	}
# 	const rfc822message = "From: {headers.from}\r\nTo: {headers.to}\r\nSubject: {headers.subject}\r\nDate: {headers.date}\r\n\r\n{text}"
# 	const dkimHeader = createDKIMHeader({ domain, selector: 'default', privateKey, rfc822message })
# 	const fullMessage = "{dkimHeader}\r\n{rfc822message}"
# 	const client = new SMTPClient { host: mxHost, port: 25 }
# 	try
# 		await client.connect!
# 		await client.greet { hostname: domain }
# 		await client.startTLS!
# 		await client.greet { hostname: domain }
# 		await client.mail { from }
# 		await client.rcpt { to }
# 		await client.data fullMessage
# 		await client.quit!
# 		console.log 'Email sent successfully!'
# 	catch err
# 		console.error 'Error sending email:', err
import nodemailer from 'nodemailer'

const transporter = nodemailer.createTransport { host: 's144.cyber-folks.pl', port: 465, secure: true, auth: {user: 'testing@leonardossa.com', pass: '2Kosikosi!',}, }

export def sendEmail email, subject, text, html
	await transporter.sendMail {
		from: 'noreply@quiz.com'
		to: email
		subject: subject
		text: text
		html: html
	}
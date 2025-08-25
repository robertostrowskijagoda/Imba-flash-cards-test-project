import { serve } from '@hono/node-server'
import { serveStatic } from '@hono/node-server/serve-static'
import { setCookie, getCookie, deleteCookie } from 'hono/cookie'
import { HTTPException } from 'hono/http-exception'
import { Hono } from 'hono'
import jwt from 'jsonwebtoken'
import Database from 'better-sqlite3'
import { sendEmail } from './email'
import index from '../client/index.html'

const db = Database('quiz.db')
# REMOVE FROM CODE!
const JWT_SECRET = "3YdLeFVVwGhXU75jDyWVKp3ByYDjBebbmpS6kzgrrxrm5LbiAK3yi8E9IDG2n3TXnjrwOzVokhU9xianepnwlbnDE3OMClnpMseCqb9vxcAbLTjLsczAlpQkUrEAqrqc58wAjMAutm84TB94trXT4vY6GFZAEVsGnp8rB5w3NA5nnB6SrFXSGooF8DTySoMzmThY4grojghN6tchVyMALIuTbJp6WrLU6hNCLh4nmIzraucZy93yGgQKEgXHtStH"

db.prepare("""
	CREATE TABLE IF NOT EXISTS questions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		text TEXT NOT NULL,
		author TEXT NOT NULL
	)
""").run!

db.prepare("""
	CREATE TABLE IF NOT EXISTS answers (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		question_id INTEGER,
		text TEXT NOT NULL,
		correct INTEGER DEFAULT 0,
		FOREIGN KEY(question_id) REFERENCES questions(id)
	)
""").run!

db.prepare("""
	CREATE TABLE IF NOT EXISTS tokens (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		expires INTEGER,
		email TEXT NOT NULL,
		token TEXT NOT NULL
	)
""").run!

setInterval(update, 5000)

def update
	autoDeleteOldTokens!

def verify c
	const token = getCookie c, 'session'
	unless token
		return {data: "Not logged in", code: 401}
	try
		const decoded = jwt.verify token, JWT_SECRET
		return {data: decoded, code: 200}
	catch e
		return {data: "Invalid session", code: 401}

def autoDeleteOldTokens
	db.prepare("DELETE FROM tokens WHERE expires < ?").run(Date.now())

def generateAndSaveToken email
	const token = Buffer.from(crypto.randomUUID()).toString("base64")
	db.prepare("INSERT INTO tokens (expires, email, token) VALUES (?, ?, ?)").run(Date.now() + (1000 * 60 * 15), email, token)
	token

def sendVerifyEmail email, token
	sendEmail email, "test", "test", "test"

let app = new Hono!

app.use "/resources/*", serveStatic({root: "./"})

app.get "/resources/*", do(c)
	throw new HTTPException(404, { message: "No such resource" })

app.get "/api/questions", do(c)
	let questions = db.prepare("SELECT * FROM questions").all!
	let result = []
	for q in questions
		let answers = db.prepare("SELECT * FROM answers WHERE question_id = ?").all(q.id)
		result.push({id: q.id, text: q.text, author: q.author, answers: answers})
	c.json result

app.post "/api/questions", do(c)
	console.log "1"
	authData = verify c
	if authData.code != 200
		return c.json {ok: no}
	let {text, answers} = await c.req.json!
	let info = db.prepare("INSERT INTO questions (text, author) VALUES (?, ?)").run(text, authData.data.email)
	for ans in answers
		db.prepare("INSERT INTO answers (question_id, text, correct) VALUES (?, ?, ?)")
			.run(info.lastInsertRowid, ans.text, (if ans.correct then 1 else 0))
	c.json {ok: yes}

app.delete "/api/questions", do(c)
	if (verify c).code != 200
		return c.json {ok: no}
	db.prepare("DELETE FROM answers").run!
	db.prepare("DELETE FROM questions").run!
	c.json {ok: yes}

app.post "/api/check", do(c)
	let answers = await c.req.json!
	let score = 0
	for item in answers
		let data = db.prepare("SELECT correct FROM answers WHERE id = ?").get(item)
		if data.correct
			score++
	c.json {score: score, total: answers.length}

app.get "/login/:token", do(c)
	const base64Token = await c.req.param 'token'
	const data = db.prepare("SELECT email FROM tokens WHERE token = ?").get(base64Token)
	if data && data.email
		db.prepare("DELETE FROM tokens WHERE token = ?").run(base64Token)
		const token = jwt.sign { email: data.email }, JWT_SECRET, { expiresIn: '1d' }
		setCookie c, "session", token, { 
			httpOnly: yes
			secure: no # Na produkcji ma być "yes"
			sameSite: "lax"
			path: "/"
			maxAge: 60 * 60 * 24
		}
	else
		return c.text "Link jest już nieważny"
	c.text "Jesteś zalogowany, możesz zamknąć tę stronę"

app.post "/api/verify", do(c)
	const data = await c.req.json!
	const token = generateAndSaveToken data.email
	sendEmail data.email, "Quiz login", "Your login link: localhost:8080/login/{token}", "Your login link: localhost:8080/login/{token}"
	c.json { ok: yes }

app.post "/api/logout", do(c)
	const ret = deleteCookie c, "session", {
		path: '/'
	}
	c.json { ok: yes }

app.get '/api/me', do(c)
	const status = verify c
	if status.code === 200
		return c.json {user: status.data.email}
	c.json { status }

app.get "*", do(c)
	c.html index.body

imba.serve serve({fetch: app.fetch, port:8080})
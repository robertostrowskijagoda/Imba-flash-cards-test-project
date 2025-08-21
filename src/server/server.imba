import { serve } from '@hono/node-server'
import { serveStatic } from '@hono/node-server/serve-static'
import { setCookie, getCookie, deleteCookie } from 'hono/cookie'
import { Hono } from 'hono'
import { logger } from 'hono/logger'
import { Magic } from '@magic-sdk/admin';
import jwt from 'jsonwebtoken'
import Database from 'better-sqlite3'
import index from '../client/index.html'

const db = Database('quiz.db')
# REMOVE FROM CODE!
const JWT_SECRET = "3YdLeFVVwGhXU75jDyWVKp3ByYDjBebbmpS6kzgrrxrm5LbiAK3yi8E9IDG2n3TXnjrwOzVokhU9xianepnwlbnDE3OMClnpMseCqb9vxcAbLTjLsczAlpQkUrEAqrqc58wAjMAutm84TB94trXT4vY6GFZAEVsGnp8rB5w3NA5nnB6SrFXSGooF8DTySoMzmThY4grojghN6tchVyMALIuTbJp6WrLU6hNCLh4nmIzraucZy93yGgQKEgXHtStH"
const magic = new Magic "sk_live_F9C3872036DC264C" # REMOVE FROM CODE!

def verify c
	const token = getCookie c, 'session'
	unless token
		return {data: "Not logged in", code: 401}
	try
		const decoded = jwt.verify token, JWT_SECRET
		return {data: decoded, code: 200}
	catch e
		return {data: "Invalid session", code: 401}

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

let app = new Hono!

app.use logger!

app.use "/resources/*", serveStatic({root: "./resources"})

app.get "/api/questions", do(c)
	let questions = db.prepare("SELECT * FROM questions").all!
	let result = []
	for q in questions
		let answers = db.prepare("SELECT * FROM answers WHERE question_id = ?").all(q.id)
		result.push({id: q.id, text: q.text, author: q.author, answers: answers})
	c.json result

app.post "/api/questions", do(c)
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

app.post '/api/session', do(c)
	const auth = c.req.header "authorization"
	unless auth
		return c.text "Missing Authorization header", 401
	const didToken = auth.slice 7
	await magic.token.validate didToken
	const metadata = await magic.users.getMetadataByToken didToken
	const token = jwt.sign { email: metadata.email }, JWT_SECRET, { expiresIn: '1d' }
	setCookie c, "session", token, { 
		httpOnly: yes
		secure: no # Na produkcji ma być "yes"
		sameSite: "lax"
		path: "/"
		maxAge: 60 * 60 * 24
	}
	c.json {ok: yes}

app.post "/api/logout", do(c)
	const ret = deleteCookie c, "session", {
		path: '/'
	}
	c.json { ok: yes }

app.get '/api/me', do(c)
	const status = verify c
	if status.code === 200
		return c.json {user: status.data.email}
	c.text status.text, status.code

app.get "*", do(c)
	c.html index.body

imba.serve serve({fetch: app.fetch, port:8080})

# Pytania:
# 1. Gdzie trzymać tokeny?
# 2. Dlaczego na kursie pokazywali mi "do (parametr)", a tutaj muszę robić "do |parametr|"? Zmieniła się wersja?
# 3. Co byś tu poprawił w stylu/składni?
# 4. Czy coś byś tu poprawił pod kątem security? Może jakieś ustawienia cookie? 
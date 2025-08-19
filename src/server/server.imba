import { serve } from '@hono/node-server'
import { serveStatic } from '@hono/node-server/serve-static'
import {Hono} from 'hono'
import Database from 'better-sqlite3'
import {serve as imba-serve} from 'imba'
import index from '../client/index.html'

let db = Database('quiz.db')

db.prepare("""
	CREATE TABLE IF NOT EXISTS questions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		text TEXT NOT NULL
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

app.get "/api/questions", do |c|
	let questions = db.prepare("SELECT * FROM questions").all!
	let result = []
	for q in questions
		let answers = db.prepare("SELECT * FROM answers WHERE question_id = ?").all(q.id)
		result.push({id: q.id, text: q.text, answers})
	c.json result

app.post "/api/questions", do |c|
	let {text, answers} = await c.req.json!
	let info = db.prepare("INSERT INTO questions (text) VALUES (?)").run(text)
	console.log(answers)
	for ans in answers
		db.prepare("INSERT INTO answers (question_id,text,correct) VALUES (?,?,?)")
			.run(info.lastInsertRowid, ans.text, (if ans.correct then 1 else 0))
	console.log("1: {JSON.stringify(db.prepare("SELECT * FROM questions").all())}")
	console.log("2: {JSON.stringify(db.prepare("SELECT * FROM answers").all())}")
	c.json {ok: true}

app.post "/api/check", do |c|
	let answers = await c.req.json!
	let score = 0
	for item in answers
		let correct = db.prepare("SELECT correct FROM answers WHERE id = ?").get(item.question_id[1])
		console.log("Answer {JSON.stringify(item)} is {(correct ? "correct" : "NOT correct")}")
		if correct and correct.correct === 1
			score++
	c.json {score: score, total: answers.length}

app.get "*", do |c|
	c.html index.body

imba.serve serve({fetch: app.fetch, port:8080})


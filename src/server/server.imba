import express from 'express'
import Database from 'better-sqlite3'
import path from 'path'
import index from '../client/index.html'

let db = Database('quiz.db')

db.prepare("""
	CREATE TABLE IF NOT EXISTS questions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		text TEXT NOT NULL
	)
""").run()

db.prepare("""
	CREATE TABLE IF NOT EXISTS answers (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		question_id INTEGER,
		text TEXT NOT NULL,
		correct INTEGER DEFAULT 0,
		FOREIGN KEY(question_id) REFERENCES questions(id)
	)
""").run()

let app = express()
app.use(express.json())

app.get "/", do(req, res)
	res.send index.body

app.get "/api/questions", do(req,res)
	let questions = db.prepare("SELECT * FROM questions").all()
	let result = []
	for q in questions
		let answers = db.prepare("SELECT * FROM answers WHERE question_id = ?").all(q.id)
		result.push({id: q.id, text: q.text, answers})
	res.json(result)

app.post "/api/questions", do(req,res)
	let {text, answers} = req.body
	let info = db.prepare("INSERT INTO questions (text) VALUES (?)").run(text)
	for ans in answers
		db.prepare("INSERT INTO answers (question_id,text,correct) VALUES (?,?,?)")
			.run(info.lastInsertRowid, ans.text, ans.correct ? 1 : 0)
	res.json({ok: true})

app.post "/api/check", do(req,res)
	let {answers} = req.body
	let score = 0
	for item in answers
		let correct = db.prepare("SELECT correct FROM answers WHERE id = ?").get(item.answer_id)
		if correct?.correct == 1
			score++
	res.json({score})

let dir = path.resolve()
app.use(express.static(path.join(dir, "dist")))

app.listen(8080, do
	console.log "✅ Server running at http://localhost:8080"
)

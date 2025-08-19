import { deepEqual } from 'assert'

tag QuizPage
	prop questions = []
	prop answers = {}

	def mount
		const res = await window.fetch "/api/questions"
		const data = await res.json!
		questions = data
		imba.commit!

	def submit
		const res = await window.fetch '/api/check', {
			method: 'POST'
			headers: { 'Content-Type': 'application/json' }
			body: JSON.stringify(Object.entries(answers).map do |qid, aid| { question_id: qid, answer_id: aid })
		}

		const data = await res.json!
		window.localStorage.setItem "answers", JSON.stringify(answers)
		window.localStorage.setItem "result", JSON.stringify(data)
		window.location.replace('/summary');

	<self [mx:auto p:4]>
		<h1 [fs:2xl fw:bold mb:4 b:flex ta:center fs:50px ff:"Comic Sans MS", "Comic Sans"]> "Quiz"
		unless questions.length === 0
			for q in questions
				<div [mb:4 p:4 b:1px rd:lg bgc:red1]>
					<p [fs:30px ta:center]> "{q.text}"
					<div [mt:2]>
						for ans in q.answers
							<label [d:block my:1 c:gray6]>
								<input [s:30px]
									type='radio'
									name="{q.id}"
									checked=(answers[q.id] == ans.id)
									@change=(answers[q.id] = ans.id)
								>
								<span [pos:relative t:-5px r:-5px fs:30px]> "{ans.text}"
		
			<button [bg:blue5 c:white px:4 py:2 rd:16px] @click=submit> "Wyślij"

tag SummaryPage
	prop score = {score:0, total:0}

	def mount
		score = JSON.parse(window.localStorage.getItem "result")
		imba.commit!

	<self [mx:auto p:4 js:center]>
		if score
			console.log(score)
			<p [fs:lg js:center fs:50px mb:50px ff:"Comic Sans MS", "Comic Sans"]> "Twój wynik: {score.score} / {score.total}"
			<a [js:center fs:50px mb:50px] route-to="/quiz" [c:blue5 hover:underline mt:4 d:block]> "Spróbuj ponownie"

tag AdminPage
	prop question = ""
	prop answers = Array(6).fill("")

	def submit
		console.log(question)
		console.log(answers)
		let formatted = answers.map do |a, i|
			{ text: a, correct: i === 0 }
		formatted = formatted.filter do |a|
			a.text.trim()
		if question.trim() and formatted.length > 1 and formatted[0] and formatted[0].text !== ""
			const res = await window.fetch "/api/questions", {
				method: "POST"
				headers: {"Content-Type": "application/json"}
				body: JSON.stringify({ text: question, answers: formatted })
			}
			
			if res.ok
				question = ""
				answers = Array(6).fill("")
				imba.commit()
				console.log("Dodano pytanie!") 
			else
				console.error("Wystąpił błąd podczas dodawania pytania.")
		else
			console.error("Pytanie i co najmniej dwie odpowiedzi (w tym poprawna) są wymagane.")

	<self [mx:auto p:4]>
		<h1 [fs:2xl fw:bold mb:4 js:center fs:50px mb:50px ff:"Comic Sans MS", "Comic Sans", cursive]> "Panel administratora"
		<div [d:flex fld:column gap:2]>
			<input type="text" placeholder="Pytanie" bind=question [p:2 b:1px rd]>
			for a, i in answers
				<input 
					type="text" 
					placeholder="Odpowiedź #{i+1} {(i === 0 ? "" : "NIE")}POPRAWNA"
					bind=answers[i]
					[p:2 b:1px rd:lg]
				>
			<button @click=submit [bg:green5 c:white px:2 py:4 rd:lg]> "Dodaj pytanie"

tag App

	prop paths = [
		{path: "/quiz", tg: QuizPage, name: "Quiz"}
		{path: "/summary", tg: SummaryPage, name: "Podsumowanie"}
		{path: "/admin", tg: AdminPage, name: "Admin"}
	]
#	css @keyframes rot
#		0% rotate: 10deg
#		100% rotate: 0deg

	css .nav-link
		bgc: yellow3
		bd: 0px
		c:green8
		td: none
		ff: "Comic Sans MS", "Comic Sans", cursive
		fs: 50px
		my: 30px
		rd: 10px
		rotate: 10deg rotate@hover: 0deg
# 		@hover animation: rot 2s
	<self>
		<nav [bg:gray1 p:4 mxy:25 d:flex gap:10 jc:center bxs:md]>
			for path of paths
				<button.nav-link route-to=path.path> path.name

		<main>
			<{paths[0].tg} route=paths[0].path>
			<{paths[1].tg} route=paths[1].path>
			<{paths[2].tg} route=paths[2].path>
#			for path of paths
#				<{path.tg} route=path.path>
#				console.log("{path.tg.nodeName} {path.path}")

imba.mount <App>
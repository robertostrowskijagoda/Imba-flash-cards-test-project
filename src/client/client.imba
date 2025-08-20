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
			body: JSON.stringify(Array.from(Object.values(answers)))
		}
		const data = await res.json!
		window.localStorage.setItem("summary", JSON.stringify(data)) # USE EVENTS!
		window.location.replace('/summary')

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
									checked=(answers[q.id] === ans.id)
									@change=(answers[q.id] = ans.id)
								>
								<span [pos:relative t:-5px r:-5px fs:30px]> "{ans.text}"
		
			<button [js:center bg:blue5 c:white px:4 py:2 rd:16px w:50% mx:25% h:80px] @click=submit> "Wyślij"

tag SummaryPage
	prop score = {score:0, total:0}

	def mount
		score = JSON.parse(window.localStorage.getItem("summary")) # USE EVENTS!
		window.localStorage.removeItem("summary") # USE EVENTS!

	<self [mx:auto p:4 js:center]>
		if score
			console.log(score)
			<p [fs:lg js:center fs:50px mb:50px ff:"Comic Sans MS", "Comic Sans"]> "Twój wynik: {score.score} / {score.total}"
			<a [js:center fs:50px mb:50px] route-to="/quiz" [c:blue5 hover:underline mt:4 d:block]> "Spróbuj ponownie"

tag AdminPage
	prop question = ""
	prop answers = Array(6).fill("")

	def submit
		let formatted = answers.map do |ans, idx|
			{ text: ans, correct: idx === 0 }
		if formatted[0].text.trim!
			formatted = formatted.filter do |data|
				data.text.trim!
			if question.trim! and formatted.length > 1
				const res = await window.fetch "/api/questions", {
					method: "POST"
					headers: {"Content-Type": "application/json"}
					body: JSON.stringify({ text: question, answers: formatted })
				}
				if res.ok
					question = ""
					answers = Array(6).fill("")
					imba.commit!
				else
					console.error("Wystąpił błąd podczas dodawania pytania.")
			else
				console.error("Pytanie i co najmniej dwie odpowiedzi są wymagane.")
		else
			console.error("Poprawna odpowiedź jest wymagana!")

	def clear
		await window.fetch "/api/questions", {method: "DELETE"}

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
			<button @click=clear [bg:red5 c:white px:2 py:4 rd:lg]> "Skasuj wszystkie pytania"

tag App

	prop paths = [
		{path: "/quiz", tg: QuizPage, name: "Quiz", visible: yes}
		{path: "/summary", tg: SummaryPage, name: "Podsumowanie", visible: no}
		{path: "/admin", tg: AdminPage, name: "Admin", visible: yes}
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
				if path.visible
					<button.nav-link route-to=path.path> path.name

		<main>
			<{paths[0].tg} route=paths[0].path>
			<{paths[1].tg} route=paths[1].path>
			<{paths[2].tg} route=paths[2].path>
#			for path of paths
#				<{path.tg} route=path.path>
#				console.log("{path.tg.nodeName} {path.path}")

imba.mount <App>
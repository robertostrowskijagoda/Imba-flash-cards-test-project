tag QuizPage
	prop questions = []
	prop answers = {}
	prop loaded? = no

	def mount
		const res = await fetch "/api/questions"
		const data = await res.json!
		questions = data
		loaded = true
		imba.commit!

	def toggleAnswer qid, aid
		answers[qid] = aid

	def submit
		const res = await fetch '/api/check', {
			method: 'POST'
			headers: { 'Content-Type': 'application/json' }
			body: JSON.stringify({
				answers: Object.entries(answers).map do |qid, aid| {
					question_id: qid
					answer_id: aid
				}
			})
		}
		
		const data = await res.json!
		Imba.navigate '/summary', {let: data}

	<self [mx:auto p:4]>
		<h1 [fs:2xl fw:bold mb:4]> "Quiz"
		
		unless loaded?
			<p> "Ładowanie..."
		else
			for q in questions
				<div [mb:4 p:4 b:1px rd:lg]>
					<p [fw:font-semibold]> "{q.text}"
					
					<div [mt:2]>
						for ans in q.answers
							<label [d:block my:1 c:gray6]>
								<input 
									type='radio'
									name="{q.id}"
									checked=(answers[q.id] == ans.id)
									@change=(toggleAnswer(q.id, ans.id))
								>
								<span> "{ans.text}"
		
		<button [bg:blue5 c:white px:4 py:2 rd:lg] @click=submit> "Wyślij"

tag SummaryPage
	prop score = 0

	def setup
		let data = Imba.let
		self.score = data?.score or 0

	<self [mx:auto p:4]>
		<h1 [fs:2xl fw:bold mb:4]> "Podsumowanie"
		<p [fs:lg]> "Twój wynik: {score}"
		<a route-to="/quiz" [c:blue5 hover:underline mt:4 d:block]> "Spróbuj ponownie"

tag AdminPage
	prop question = ""
	prop answers = Array(6).fill("")

	def submit
		let formatted = answers.filter(do(a) a.trim()).map do(a, i)
			{ text: a, correct: i == 0 }
		
		if question.trim() and formatted.length > 0
			const res = await fetch "/api/questions", {
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
			console.error("Pytanie i co najmniej jedna odpowiedź są wymagane.")

	<self [mx:auto p:4]>
		<h1 [fs:2xl fw:bold mb:4]> "Panel administratora"
		<div [d:flex f:col gap:2]>
			<input type="text" placeholder="Pytanie" bind=question [p:2 b:1px rd]>
			for a, i in answers
				<input 
					type="text" 
					placeholder="Odpowiedź #{i+1} (pierwsza poprawna)"
					bind=a
					[p:2 b:1px rd]
				>
			<button @click=submit [bg:green5 c:white px:4 py:2 rd:lg]> "Dodaj pytanie"

tag App
	<self>
		<nav [bg:gray1 p:4 mb:4 d:flex gap:4]>
			<a route-to="/quiz" [c:blue5 hover:underline]> "Quiz"
			<a route-to="/summary" [c:blue5 hover:underline]> "Podsumowanie"
			<a route-to="/admin" [c:blue5 hover:underline]> "Admin"

		<main>
			<div route="/quiz" default>
				<QuizPage>
			<div route="/summary">
				<SummaryPage>
			<div route="/admin">
				<AdminPage>

imba.mount <App>

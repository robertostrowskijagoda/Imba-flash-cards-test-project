import i18n from 'i18next'
import i18next-lang-detector from 'i18next-browser-languagedetector'
import i18next-resources from 'i18next-resources-to-backend'

def login email
	console.log("login")
	# const didToken = await magic.auth.loginWithMagicLink { email } # Czy nawiasy {} są tu potrzebne? Dlaczego?
	# await window.fetch '/api/session', {
	# 	method: 'POST'
	# 	headers: {
	# 		Authorization: "Bearer {didToken}",
	# 	}
	# }

tag QuizPage
	prop questions = []
	prop answers = {}

	def mount
		const res = await window.fetch "/api/questions"
		const data = await res.json!
		questions = shuffle data
		for q in questions
			q.answers = shuffle q.answers
		imba.commit!

	def submit
		const res = await window.fetch '/api/check', {
			method: 'POST'
			headers: { 'Content-Type': 'application/json' }
			body: JSON.stringify(Array.from(Object.values(answers))) # Czy to można napisać bardziej w IMBA stylu?
		}
		const data = await res.json!
		imba.emit "summary", data
		window.location.replace '/summary'

	def shuffle array
		let currentIndex = array.length
		while currentIndex !== 0
			currentIndex--
			let randomIndex = Math.floor(Math.random() * array.length)
			const tmp = array[currentIndex]
			array[currentIndex] = array[randomIndex]
			array[randomIndex] = tmp
		array

	<self [mx:auto p:4]>
		<h1 [fs:2xl fw:bold mb:4 b:flex ta:center fs:50px ff:"Comic Sans MS", "Comic Sans"]> "{i18n.t "Quiz"}"
		unless questions.length === 0
			for q in questions
				<div [mb:4 p:4 b:1px rd:lg bgc:red1]>
					<p [fs:30px ta:center]> "{i18n.t "Author"}: {q.author} {i18n.t "Question"}: {q.text}"
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
		
			<button [js:center bg:blue5 c:white px:4 py:2 rd:16px w:50% mx:25% h:80px] @click=submit> "{i18n.t "Send"}"

tag SummaryPage
	prop score = {score:0, total:0}

	def awaken
		imba.listen "summary" do(score)
			score = score
			console.log(score)
			imba.commit!

	<self [mx:auto p:4 js:center]>
		if score
			<p [fs:lg js:center fs:50px mb:50px ff:"Comic Sans MS", "Comic Sans"]> "{i18n.t "Your score"}: {score.score} / {score.total}"
			<a [js:center fs:50px mb:50px] route-to="/quiz" [c:blue5 hover:underline mt:4 d:block]> "{i18n.t "Try again"}"

tag AdminPage
	prop question = ""
	prop answers = Array(6).fill "" # Czy tu można napisać tak? Array 6 .fill ""

	def mount
		const res = await window.fetch "/api/me"
		if res.status === 401
			const email = window.prompt "{i18n.t "email-login-prompt"}:"
			if email
				await login email
				imba.commit!
			else
				window.location.replace "/quiz"
	  
	def submit
		let formatted = answers.map do(ans, idx) { text: ans, correct: idx === 0 }
		if formatted[0].text.trim!
			formatted = formatted.filter do(data)
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
					window.alert "{i18n.t "admin.submit.error.backend"}"
			else
				window.alert "{i18n.t "admin.submit.error.no-question-or-less-than-2-answers"}"
		else
			window.alert "{i18n.t "admin.submit.error.no-proper-answer"}"

	def clear
		await window.fetch "/api/questions", { method: "DELETE" }

	def logOut
		await window.fetch "/api/logout", { method: "POST" }
		window.location.replace "/quiz"

	<self [mx:auto p:4]>
		<h1 [fs:2xl fw:bold mb:4 js:center fs:50px mb:50px ff:"Comic Sans MS", "Comic Sans", cursive]> "{i18n.t "Administrator panel"}"
		<div [d:flex fld:column gap:2]>
			<input type="text" placeholder="Pytanie" bind=question [p:2 b:1px rd]>
			for a, i in answers
				<input 
					type="text" 
					placeholder="Odpowiedź #{i+1} {(i === 0 ? "" : "{i18n.t "quiz.question.answer.placeholder.not-prefix"}")}{i18n.t "quiz.question.answer.placeholder.proper-sufix"}"
					bind=answers[i]
					[p:2 b:1px rd:lg]
				>
			<button @click=submit [bg:green5 c:white px:2 py:4 rd:lg]> "{i18n.t "Add question"}"
			<button @click=clear [bg:red5 c:white px:2 py:4 rd:lg]> "{i18n.t "Delete all questions"}"
			<button @click=logOut [bg:red5 c:white px:2 py:4 rd:lg]> "{i18n.t "Logout"}"

tag App

	prop paths = []

	def setup
		if paths.length === 0
			i18n.use(i18next-lang-detector).use(
				i18next-resources do(lang, ns) 
					const res = await window.fetch "/resources/locales/{lang}/{ns}.json"
					res.status == 404 ? null : await res.json!
			).init({
				fallbackLng: "en"
				debug: yes
			}) do
				imba.commit!
				paths = [
					{path: "/quiz", tg: QuizPage, name: "{i18n.t "Quiz"}", visible: yes}
					{path: "/summary", tg: SummaryPage, name: "{i18n.t "Summary"}", visible: no}
					{path: "/admin", tg: AdminPage, name: "{i18n.t "Administrator panel"}", visible: yes}
				]

	css @keyframes rot
		0% rotate: 10deg
		100% rotate: 0deg

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
		tween: all 350ms ease

	<self>
		<nav [bg:gray1 p:4 mxy:25 d:flex gap:10 jc:center bxs:md]>
			for path in paths
				if path.visible
					<button.nav-link route-to=path.path> path.name

		<main>
			if paths.length === 0
				<h1> "LOADING..."
			else
				for path in paths
					<{path.tg} route=path.path>

imba.mount <App>

# Pytania:
# 1. W jaki sposób w Imba napisać coś takiego? metodaA(metodaB()).metodaC()
# 2. Dlaczego nie działają mi eventy? Co robię źle? 
# Zakładam, że problemem jest to, że próbuję posługiwać się eventami między różnymi tagami, 
# które nie są aktywne wszystkie na raz, jak to więc zrobić poprawnie, żeby nie posługiwać się localStorage?
tag QuizPage
	prop questions = []
	prop answers = {}
	prop loaded = false

	# Fetches questions when the component is mounted to the DOM

	def mount
		fetch("/api/questions")
		.then(res => res.json())
		.then do |data|
			self.questions = data
			self.loaded = true
			imba.commit()

	# Updates the selected answer for a given question
	def toggleAnswer qid, aid
		answers[qid] = aid
		self.answers = answers

	# Submits the answers to the server for checking
	def submit
		fetch("/api/check", {
			method: "POST",
			headers: {"Content-Type": "application/json"},
			body: JSON.stringify({
				# Correctly map the answers object to the required format
				answers: Object.entries(answers).map do |(qid, aid)|
					{ question_id: qid, answer_id: aid }
			})
		})
		.then(res => res.json())
		.then do |data|
			# Navigate to the summary page with the result data
			Router.navigate("/summary", { let: data })

	<self>
		<div.container.mx-auto.p-4>
			<h1.text-2xl.font-bold.mb-4> "Quiz" </h1>
			if not loaded
				<p> "Ładowanie..." </p>
			else
				for q in questions
					<div.question.mb-4.p-4.border.rounded>
						<p.font-semibold> {q.text} </p>
						<div.answers.mt-2>
							for ans in q.answers
								<label.block.my-1>
									<input 
										type="radio" 
										name={q.id} 
										checked={answers[q.id] == ans.id}
										@change={toggleAnswer(q.id, ans.id)}
									>
									<span> {ans.text} </span>
								</label>
				<button.bg-blue-500.text-white.px-4.py-2.rounded @click={submit}> "Wyślij" </button>

tag SummaryPage
	prop score = 0

	# Setup component state from router data
	def setup
		let data = Router.let
		self.score = data?.score or 0

	<self>
		<div.container.mx-auto.p-4>
			<h1.text-2xl.font-bold.mb-4> "Podsumowanie" </h1>
			<p.text-lg> "Twój wynik: {score}" </p>
			<Link to="/quiz" class="text-blue-500 hover:underline mt-4 inline-block"> "Spróbuj ponownie" </Link>
		</div>

tag AdminPage
	prop question = ""
	prop answers = Array(6).fill("")

	# Submits a new question to the server
	def submit
		# Filter out empty answers and format the data
		let formatted = answers.filter(a => a.trim()).map do |a, i|
			{ text: a, correct: i == 0 }
		
		# Ensure there is a question and at least one answer
		if question.trim() and formatted.length > 0
			fetch("/api/questions", {
				method: "POST",
				headers: {"Content-Type": "application/json"},
				body: JSON.stringify({ text: question, answers: formatted })
			})
			.then(res => res.json())
			.then do
				# Reset form fields after successful submission
				self.question = ""
				self.answers = Array(6).fill("")
				imba.commit()
				# Use a more modern, non-blocking notification if possible
				console.log("Dodano pytanie!") 
		else
			console.error("Pytanie i co najmniej jedna odpowiedź są wymagane.")


	<self>
		<div.container.mx-auto.p-4>
			<h1.text-2xl.font-bold.mb-4> "Panel administratora" </h1>
			<div.flex.flex-col.gap-2>
				<input type="text" placeholder="Pytanie" bind=question class="p-2 border rounded">
				# The first answer is considered the correct one
				for a, i in answers
					<input type="text" placeholder={"Odpowiedź #{i+1} (pierwsza poprawna)"} bind={answers[i]} class="p-2 border rounded">
				<button @click={submit} class="bg-green-500 text-white px-4 py-2 rounded"> "Dodaj pytanie" </button>
			</div>
		</div>

tag App
	<self>
		<Router>
			<nav.bg-gray-100.p-4.mb-4>
				<div.container.mx-auto.flex.gap-4>
					<Link to="/quiz" class="text-blue-500 hover:underline"> "Quiz" </Link>
					<Link to="/summary" class="text-blue-500 hover:underline"> "Podsumowanie" </Link>
					<Link to="/admin" class="text-blue-500 hover:underline"> "Admin" </Link>
				</div>
			</nav>
			<main>
				# Routes must be self-closing or have content
				<Route path="/quiz" component={QuizPage} default/>
				<Route path="/summary" component={SummaryPage}/>
				<Route path="/admin" component={AdminPage}/>
			</main>
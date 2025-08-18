import index from './src/client/index.html'
import express from 'express'
const app = express!
const port = process.env.PORT or 3000

app.get '/' do(req, res)
	res.send index.body

imba.serve app.listen(port)

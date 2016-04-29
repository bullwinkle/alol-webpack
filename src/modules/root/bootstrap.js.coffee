@Iconto.module 'root', (Root) ->
	Root.router = new Root.Router controller: new Root.Controller()

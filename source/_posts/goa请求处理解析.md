title: goa请求处理解析
date: 2016-08-16 15:39:41
tags: [micro service,golang]
---
##### 1. 入口
`app.MountXXXController` -> 
`service.Mux.Handle("GET", "/add/:left/:right", ctrl.MuxHandler("Add", h, nil))` ->` ctrl.MuxHandler("Add", h, nil)`


在 ` ctrl.MuxHandler("Add", h, nil)` 中返回一个 先Invoke用户实现的对应请求的逻辑方法,再依次Invoke middleware 的函数：
```golang
// MuxHandler wraps a request handler into a MuxHandler. The MuxHandler initializes the request
// context by loading the request state, invokes the handler and in case of error invokes the
// controller (if there is one) or Service error handler.
// This function is intended for the controller generated code. User code should not need to call
// it directly.
func (ctrl *Controller) MuxHandler(name string, hdlr Handler, unm Unmarshaler) MuxHandler {
	// Use closure to enable late computation of handlers to ensure all middleware has been
	// registered.
	var handler Handler

	return func(rw http.ResponseWriter, req *http.Request, params url.Values) {
		// Build handler middleware chains on first invocation
		if handler == nil {
			handler = func(ctx context.Context, rw http.ResponseWriter, req *http.Request) error {
				if !ContextResponse(ctx).Written() {
					return hdlr(ctx, rw, req)
				}
				return nil
			}
			chain := append(ctrl.Service.middleware, ctrl.middleware...)
			ml := len(chain)
			for i := range chain {
				handler = chain[ml-i-1](handler)
			}
		}

		// Build context
		ctx := NewContext(WithAction(ctrl.Context, name), rw, req, params)

		// Protect against request bodies with unreasonable length
		if ctrl.MaxRequestBodyLength > 0 {
			req.Body = http.MaxBytesReader(rw, req.Body, ctrl.MaxRequestBodyLength)
		}

		// Load body if any
		if req.ContentLength > 0 && unm != nil {
			if err := unm(ctx, ctrl.Service, req); err != nil {
				if err.Error() == "http: request body too large" {
					msg := fmt.Sprintf("request body length exceeds %d bytes", ctrl.MaxRequestBodyLength)
					err = ErrRequestBodyTooLarge(msg)
				} else {
					err = ErrBadRequest(err)
				}
				ctx = WithError(ctx, err)
			}
		}

		// Invoke handler
		if err := handler(ctx, ContextResponse(ctx), req); err != nil {
			LogError(ctx, "uncaught error", "err", err)
			respBody := fmt.Sprintf("Internal error: %s", err) // Sprintf catches panics
			ctrl.Service.Send(ctx, 500, respBody)
		}
	}
}
```

而`service.Mux.Handle("GET", "/add/:left/:right", ctrl.MuxHandler("Add", h, nil))` 就是告诉 httptreemux 请求 url对应hander是 ctrl.MuxHandler
```golang
func (m *mux) Handle(method, path string, handle MuxHandler) {
	hthandle := func(rw http.ResponseWriter, req *http.Request, htparams map[string]string) {
		params := req.URL.Query()
		for n, p := range htparams {
			params.Set(n, p)
		}
		handle(rw, req, params)
	}
	m.handles[method+path] = handle
	m.router.Handle(method, path, hthandle)
}
```

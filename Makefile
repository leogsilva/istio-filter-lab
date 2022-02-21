WAIT := 200s
KUBECTL = kubectl --kubeconfig=.kubeconfig
ISTIOCTL = istioctl
NAME = $$(echo $@ | cut -d "-" -f 2- | sed "s/%*$$//")
DOCKER = docker


install-istio-%: create-% env-% 
	$(ISTIOCTL) operator init 
	$(KUBECTL) apply -f default-profile.yaml

install-nginx-%: env-%
	$(KUBECTL) create ns ingress-nginx || true
	$(KUBECTL) label namespace ingress-nginx istio-injection=enabled || true
	$(KUBECTL) apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml
	$(KUBECTL) wait --for=condition=Available deployment/ingress-nginx-controller -n ingress-nginx --timeout=160s

install-httpbin-%: install-istio-% env-%
	$(KUBECTL) patch svc ingress-nginx-controller -n ingress-nginx --patch "$$(cat patches/patch_ingresscontroller.yaml)"
	$(KUBECTL) patch svc istio-ingressgateway -n istio-system --patch "$$(cat patches/patch_ingressgateway.yaml)"
	$(KUBECTL) label namespace default istio-injection=enabled || true
	$(KUBECTL) apply -f httpbin.yaml
	$(KUBECTL) apply -f lua_filter.yaml

test-%: env-%
	$(eval POD := $(shell $(KUBECTL) get pods -n istio-system -lapp=istio-ingressgateway -o=name))	
	$(KUBECTL) exec -ti $(POD) -n istio-system -- curl http://istio-ingressgateway/mycontext/get

delete-%:
	@kind delete cluster --name $(NAME)

env-%:
	@kind get kubeconfig --name $(NAME) > .kubeconfig

clean:
	@kind get clusters | xargs -L1 -I% kind delete cluster --name %

list:
	@kind get clusters

create-%:
	-@sh/kind-registry.sh $(NAME) $(WAIT)


.PHONY: create-% delete-% env-% clean list install-istio-% install-httpbin-%
export default {
  fetch(request, env) {
    return env.BACKEND.fetch(request);
  },
};

// Mock for Vue SweetAlert2

export default {
  install(Vue) {
    Vue.prototype.$swal = jest.fn().mockResolvedValue({
      isConfirmed: true,
      isDenied: false,
      isDismissed: false,
      dismiss: null,
      value: true
    })
  }
}
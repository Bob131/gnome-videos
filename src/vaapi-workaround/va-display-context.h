#include <va/va_backend.h>

int va_display_context_get_driver_name (
  struct VADisplayContext* context,
  char** driver_name
) {
  return context->vaGetDriverName (context, driver_name);
}

export const formatError = (joiError) => {
  const errors = {};

  joiError.details.forEach((error) => {
    const key = error.path.join('.');
    errors[key] = errors[key] || [];
    errors[key].push(error.message);
  });

  return errors;
}
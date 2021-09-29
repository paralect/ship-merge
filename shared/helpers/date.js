export const handleDateFormat = (date) => {
  if (!date) return;
  const currentDate = new Date(date);
  const formatDate = currentDate.toLocaleString('en-US', {
    day: '2-digit',
    year: 'numeric',
    month: '2-digit',
    hour: 'numeric',
    minute: 'numeric',
    hour12: false,
  }).replace(/,/g, '');

  return formatDate;
};

export const transformDate = (consDate) => {
  if (!consDate) return;
  let dd = consDate.getDate();
  let mm = consDate.getMonth() + 1;
  const yyyy = consDate.getFullYear();

  if (dd < 10) {
    dd = `0${dd}`;
  }

  if (mm < 10) {
    mm = `0${mm}`;
  }

  return `${mm}/${dd}/${yyyy}`;
};

const pad = (value) => {
  return value < 10 ? `0${value}` : value;
}

export const createOffset = (date) => {
  if (!date) return;
  const sign = (date.getTimezoneOffset() > 0) ? '-' : '+';
  const offset = Math.abs(date.getTimezoneOffset());
  const hours = Math.floor(offset / 60);
  const minutes = pad(offset % 60);
  return `${sign + hours}:${minutes}`;
};

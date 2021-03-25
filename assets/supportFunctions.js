export function randomInt(low, high) {
    return Math.floor(Math.random() * (high - low) + low)
  };
  
export function random(low, high) {
    return Math.random() * (high - low) + low
  };
  
export function sleep(milliseconds) {
    const date = Date.now();
    let currentDate = null;
    do {
      currentDate = Date.now();
    } while (currentDate - date < milliseconds);
};
  
import { test, expect } from '@playwright/test';

// The web build is compiled with this SUPABASE_URL (see README.md). Nothing
// runs there: the test answers the sign-in request itself.
const supabaseUrl = 'http://127.0.0.1:54321';

test('sends a magic link from the sign-in page', async ({ page }) => {
  const otpRequests: unknown[] = [];
  await page.route(`${supabaseUrl}/auth/v1/otp**`, async (route) => {
    const cors = {
      'access-control-allow-origin': '*',
      'access-control-allow-headers': '*',
      'access-control-allow-methods': 'POST, OPTIONS',
    };
    if (route.request().method() === 'OPTIONS') {
      return route.fulfill({ status: 204, headers: cors });
    }
    otpRequests.push(route.request().postDataJSON());
    return route.fulfill({ status: 200, headers: cors, json: {} });
  });

  await page.goto('/');
  // Flutter draws to a canvas. Turn on its accessibility tree so the page can
  // be found by role and label, as a screen reader would.
  await page.locator('flt-semantics-placeholder').dispatchEvent('click');

  await expect(page.getByText('Sign In', { exact: true })).toBeVisible();
  await page.getByRole('textbox', { name: 'Email' }).click();
  await page.keyboard.type('alice@example.com');
  await page.getByRole('button', { name: 'Send sign-in link' }).click();

  // Look in the page itself, not in the copy announced to screen readers.
  await expect(
    page.locator('flt-semantics-host').getByText('Please check your email for a sign-in link.'),
  ).toBeVisible();
  expect(otpRequests).toEqual([
    expect.objectContaining({ email: 'alice@example.com' }),
  ]);
});

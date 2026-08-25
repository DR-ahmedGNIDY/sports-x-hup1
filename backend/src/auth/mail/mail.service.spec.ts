import { MailService } from './mail.service';

describe('MailService', () => {
  const fakeConfig = {
    get: (key: string) =>
      key === 'FRONTEND_URL' ? 'https://app.sportxhub.com' : undefined,
  };

  it('builds the reset URL from FRONTEND_URL and delegates to the injected provider', async () => {
    const provider = {
      sendPasswordResetEmail: jest.fn().mockResolvedValue(undefined),
    };
    const service = new MailService(provider as never, fakeConfig as never);

    await service.sendPasswordResetEmail(
      'player@example.com',
      'raw-token-value',
      'correlation-1',
    );

    expect(provider.sendPasswordResetEmail).toHaveBeenCalledWith({
      to: 'player@example.com',
      resetUrl:
        'https://app.sportxhub.com/reset-password?token=raw-token-value',
    });
  });

  // Regression test for CWE-532 (sensitive data in log files): the raw
  // reset token/URL must never reach any log statement, in success or
  // failure — only the caller-supplied, non-reversible correlationId may.
  it('never logs the raw reset token or reset URL, on success or failure', async () => {
    const logCalls: string[] = [];
    const service = new MailService(
      {
        sendPasswordResetEmail: jest.fn().mockResolvedValue(undefined),
      } as never,
      fakeConfig as never,
    );
    // Nest's Logger writes directly to stdout rather than via console.log,
    // so that's the seam to intercept here.
    const stdoutSpy = jest
      .spyOn(process.stdout, 'write')
      .mockImplementation((chunk: unknown) => {
        logCalls.push(String(chunk));
        return true;
      });

    await service.sendPasswordResetEmail(
      'player@example.com',
      'super-secret-raw-token',
      'correlation-2',
    );

    stdoutSpy.mockRestore();

    const combined = logCalls.join('\n');
    expect(combined).not.toContain('super-secret-raw-token');
    expect(combined).toContain('correlation-2');
  });

  it('swallows a provider failure rather than throwing, to avoid an enumeration-timing signal', async () => {
    const provider = {
      sendPasswordResetEmail: jest
        .fn()
        .mockRejectedValue(new Error('smtp down')),
    };
    const service = new MailService(provider as never, fakeConfig as never);

    await expect(
      service.sendPasswordResetEmail(
        'player@example.com',
        'token',
        'correlation-3',
      ),
    ).resolves.toBeUndefined();
  });
});

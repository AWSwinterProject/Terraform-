const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { BedrockRuntimeClient, InvokeModelCommand } = require('@aws-sdk/client-bedrock-runtime');

const REGION = process.env.AWS_REGION || 'ap-northeast-2';
const BEDROCK_MODEL_ID = process.env.BEDROCK_MODEL_ID; // ★ inference profile ARN을 넣을 것

const s3Client = new S3Client({ region: REGION });
const bedrockClient = new BedrockRuntimeClient({ region: REGION });

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  if (!BEDROCK_MODEL_ID) {
    throw new Error('Missing env var: BEDROCK_MODEL_ID (set to an inference profile ARN)');
  }

  for (const record of event.Records ?? []) {
    const bucket = record?.s3?.bucket?.name;
    const key = decodeURIComponent(record?.s3?.object?.key?.replace(/\+/g, ' ') || '');

    if (!bucket || !key) {
      console.warn('Skip invalid record:', JSON.stringify(record));
      continue;
    }

    // ★ 무한루프 방지: summary/에 저장된 결과는 처리하지 않음
    if (key.startsWith('summary/')) {
      console.log(`Skip summary object to avoid recursion: s3://${bucket}/${key}`);
      continue;
    }

    // ★ pdf만 처리
    if (!key.toLowerCase().endsWith('.pdf')) {
      console.log(`Skip non-pdf object: s3://${bucket}/${key}`);
      continue;
    }

    console.log(`Processing: s3://${bucket}/${key}`);

    try {
      // 1) S3에서 PDF 파일 가져오기
      const pdfData = await s3Client.send(new GetObjectCommand({
        Bucket: bucket,
        Key: key
      }));

      const pdfBytes = await pdfData.Body.transformToByteArray();
      const pdfBase64 = Buffer.from(pdfBytes).toString('base64');

      // 2) Bedrock Claude 모델로 PDF 요약 요청
      const prompt = `다음 PDF 문서를 읽고 핵심 내용을 한국어로 요약해주세요.
주요 포인트를 bullet point로 정리하고, 마지막에 전체 요약을 3문장 이내로 작성해주세요.`;

      const requestBody = {
        anthropic_version: "bedrock-2023-05-31",
        max_tokens: 4096,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "document",
                source: {
                  type: "base64",
                  media_type: "application/pdf",
                  data: pdfBase64
                }
              },
              {
                type: "text",
                text: prompt
              }
            ]
          }
        ]
      };

      // ★ 핵심: modelId에 inference profile ARN을 넣는다
      const bedrockResponse = await bedrockClient.send(new InvokeModelCommand({
        modelId: BEDROCK_MODEL_ID,
        contentType: "application/json",
        accept: "application/json",
        body: JSON.stringify(requestBody)
      }));

      const responseBody = JSON.parse(new TextDecoder().decode(bedrockResponse.body));
      const summary = responseBody?.content?.[0]?.text ?? '';

      if (!summary) {
        console.warn('Summary empty. Full response:', JSON.stringify(responseBody));
      } else {
        console.log('Summary generated successfully');
      }

      // 3) 요약 결과를 S3 /summary 경로에 JSON 형식으로 저장
      const originalFileName = key.split('/').pop().replace(/\.pdf$/i, '');
      const summaryKey = `summary/${originalFileName}_summary.json`;

      const resultJson = {
        success: true,
        fileName: originalFileName,
        originalPath: key,
        modelIdUsed: BEDROCK_MODEL_ID,
        summary,
        processedAt: new Date().toISOString()
      };

      await s3Client.send(new PutObjectCommand({
        Bucket: bucket,
        Key: summaryKey,
        Body: JSON.stringify(resultJson, null, 2),
        ContentType: 'application/json; charset=utf-8'
      }));

      console.log(`Summary saved to: s3://${bucket}/${summaryKey}`);
    } catch (error) {
      console.error(`Error processing ${key}:`, error);
      throw error;
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ message: 'PDF summarization completed' })
  };
};

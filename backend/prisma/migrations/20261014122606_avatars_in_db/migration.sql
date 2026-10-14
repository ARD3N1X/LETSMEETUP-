-- CreateTable
CREATE TABLE "avatars" (
    "user_id" UUID NOT NULL,
    "data" BYTEA NOT NULL,
    "mime_type" TEXT NOT NULL DEFAULT 'image/webp',
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "avatars_pkey" PRIMARY KEY ("user_id")
);

-- AddForeignKey
ALTER TABLE "avatars" ADD CONSTRAINT "avatars_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
